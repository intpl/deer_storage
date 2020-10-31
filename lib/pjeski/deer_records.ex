defmodule Pjeski.DeerRecords do
  import Ecto.Query, warn: false
  alias Phoenix.PubSub
  alias Pjeski.Repo
  alias DeerCache.RecordsCountsCache
  alias DeerCache.SubscriptionStorageCache

  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.Subscriptions.Subscription

  import Pjeski.DeerRecords.DeerRecord, only: [
    deer_files_stats: 1,
    append_id_to_connected_deer_records: 2,
    remove_id_from_connected_deer_records: 2,
    remove_ids_from_connected_deer_records: 2
  ]

  def at_least_one_record_with_table_id?(%Subscription{id: subscription_id}, table_id) do
    query = DeerRecord
    |> where([dr], dr.subscription_id == ^subscription_id)
    |> where([dr], dr.deer_table_id == ^table_id)
    |> limit(1)

    !!Repo.one(query)
  end

  def get_record!(id), do: Repo.get!(DeerRecord, id)
  def get_record!(%Subscription{id: subscription_id}, id), do: get_record!(subscription_id, id) # TODO remove this, refactor calls
  def get_record!(subscription_id, id) do
    DeerRecord
    |> Repo.get_by!(id: id, subscription_id: subscription_id)
  end

  def get_records!(_subscription_id, []), do: []
  def get_records!(subscription_id, ids) do
    DeerRecord |> where([r], r.id in ^ids) |> where([r], r.subscription_id == ^subscription_id) |> Repo.all()
  end

  def check_limits_and_create_record(%Subscription{deer_records_per_table_limit: limit} = subscription, attrs, cached_count) when cached_count < limit do
    create_record(subscription, attrs)
  end

  def create_record(%Subscription{} = subscription, attrs) do
    %DeerRecord{subscription_id: subscription.id}
    |> DeerRecord.changeset(attrs, subscription)
    |> Repo.insert()
    |> maybe_notify_about_record_update
    |> maybe_increment_deer_cache
  end

  def update_record(%Subscription{} = subscription, %DeerRecord{} = record, attrs) do
    record
    |> DeerRecord.changeset(attrs, subscription)
    |> Repo.update()
    |> maybe_notify_about_record_update
  end

  def change_record(%Subscription{} = subscription, record, attrs) do
    DeerRecord.changeset(record, attrs, subscription)
  end

  def delete_record(%Subscription{id: subscription_id}, %DeerRecord{subscription_id: subscription_id} = record) do
    Repo.delete(record)
    |> maybe_notify_about_record_delete
    |> maybe_decrement_deer_cache
    |> maybe_delete_deer_files_directory
    |> maybe_notify_about_deer_files_deletion
  end

  def batch_delete_records(%Subscription{id: subscription_id}, table_id, list_of_ids) do
    query = DeerRecord
    |> where([dr], dr.subscription_id == ^subscription_id)
    |> where([dr], dr.deer_table_id == ^table_id)
    |> where([dr], dr.id in ^list_of_ids)

    records = Repo.all(query)

    {files_count, kilobytes} = Enum.reduce(records, {0, 0}, fn dr, {total_files, total_kilobytes} ->
      {dr_files, dr_kilobytes} = deer_files_stats(dr)

      {total_files + dr_files, total_kilobytes + dr_kilobytes}
    end)

    {deleted_count, _} = Repo.delete_all(query)


    notify_about_deer_files_deletion(subscription_id, files_count, kilobytes)
    notify_about_batch_record_delete(subscription_id, list_of_ids)
    decrement_deer_cache(table_id, deleted_count)

    if length(records) != deleted_count, do: raise("not all records has been removed (cache is now invalid)")

    {:ok, deleted_count}
  end

  def count_records_grouped_by_deer_table_id do
    Repo.all(
      from r in DeerRecord,
      group_by: r.deer_table_id,
      select: %{deer_table_id: r.deer_table_id, count: count(r.id)}
    )
  end

  def prepend_record_with_deer_file!(record, deer_file) do
    record
    |> DeerRecord.prepend_deer_file_to_changeset(deer_file)
    |> Repo.update()
    |> maybe_notify_about_record_update
  end

  def delete_file_from_record!(subscription_id, record_id, file_id) do
    {:ok, _} = Repo.transaction(fn ->
      record = Repo.one!(from dr in DeerRecord, where: dr.id == ^record_id and dr.subscription_id == ^subscription_id, lock: "FOR UPDATE")
      deer_file = Enum.find(record.deer_files, fn deer_file -> deer_file.id == file_id end) || raise("invalid file id")

      updated_record = Repo.update!(DeerRecord.reject_file_from_changeset(record, file_id))
      File.rm!(File.cwd! <> "/uploaded_files/#{subscription_id}/#{record_id}/#{file_id}")

      notify_about_record_update(updated_record)
      notify_about_deer_files_deletion(subscription_id, 1, deer_file.kilobytes)
    end)
  end

  def disconnect_records!(%DeerRecord{subscription_id: subscription_id} = record1, %DeerRecord{subscription_id: subscription_id} = record2, subscription_id) do
    # TODO: validations
    record1_changeset = remove_id_from_connected_deer_records(record1, record2.id)
    record2_changeset = remove_id_from_connected_deer_records(record2, record1.id)

    {:ok, _} = Repo.transaction(fn ->
      Repo.update!(record1_changeset) |> notify_about_record_update
      Repo.update!(record2_changeset) |> notify_about_record_update
    end)
  end

  def connect_records!(%DeerRecord{id: id}, %DeerRecord{id: id}, _subscription_id), do: raise("attempt to connect the same record")
  def connect_records!(%DeerRecord{subscription_id: subscription_id} = record1, %DeerRecord{subscription_id: subscription_id} = record2, subscription_id) do
    # TODO: validations
    record1_changeset = append_id_to_connected_deer_records(record1, record2.id)
    record2_changeset = append_id_to_connected_deer_records(record2, record1.id)

    {:ok, _} = Repo.transaction(fn ->
      Repo.update!(record1_changeset) |> notify_about_record_update
      Repo.update!(record2_changeset) |> notify_about_record_update
    end)
  end

  def remove_orphans_from_connected_records!(%DeerRecord{connected_deer_records_ids: connected_ids}, connected_records) when length(connected_ids) == length(connected_records), do: nil
  def remove_orphans_from_connected_records!(%DeerRecord{connected_deer_records_ids: connected_ids} = record, connected_records) do
    orphans = connected_ids -- Enum.map(connected_records, fn r -> r.id end)
    changeset = remove_ids_from_connected_deer_records(record, orphans)

    Repo.update!(changeset) |> notify_about_record_update
  end

  def ensure_deer_file_exists_in_record!(deer_record, deer_file_id) do
    Enum.find(deer_record.deer_files, fn df -> df.id == deer_file_id end) || raise("invalid file id")
  end

  defp maybe_decrement_deer_cache({:error, _} = response), do: response
  defp maybe_decrement_deer_cache({:ok, %{deer_table_id: table_id} = record}) do
    decrement_deer_cache(table_id)
    {:ok, record}
  end

  defp decrement_deer_cache(table_id, by_count \\ 1) do
    GenServer.cast(RecordsCountsCache, {:decrement, table_id, by_count})
  end

  defp maybe_increment_deer_cache({:error, _} = response), do: response
  defp maybe_increment_deer_cache({:ok, %{deer_table_id: table_id} = record}) do
    GenServer.cast(RecordsCountsCache, {:increment, table_id})
    {:ok, record}
  end

  defp maybe_notify_about_record_delete({:error, _} = response), do: response
  defp maybe_notify_about_record_delete({:ok, record}) do
    PubSub.broadcast(Pjeski.PubSub, "records:#{record.subscription_id}", {:record_delete, record.id})

    {:ok, record}
  end

  defp notify_about_batch_record_delete(subscription_id, ids) do
    PubSub.broadcast(Pjeski.PubSub, "records:#{subscription_id}", {:batch_record_delete, ids})
  end

  defp maybe_notify_about_record_update({:error, _} = response), do: response
  defp maybe_notify_about_record_update({:ok, record}) do
    notify_about_record_update(record)

    {:ok, record}
  end

  defp notify_about_record_update(record) do
    PubSub.broadcast(Pjeski.PubSub, "records:#{record.subscription_id}", {:record_update, record})
  end

  defp maybe_delete_deer_files_directory({:error, _} = response), do: response
  defp maybe_delete_deer_files_directory({:ok, record}) do
    File.rm_rf!(File.cwd! <> "/uploaded_files/#{record.subscription_id}/#{record.id}")

    {:ok, record}
  end

  defp maybe_notify_about_deer_files_deletion({:error, _} = response), do: response
  defp maybe_notify_about_deer_files_deletion({:ok, record}) do
    {count, kilobytes} = deer_files_stats(record)
    notify_about_deer_files_deletion(record.subscription_id, count, kilobytes)

    {:ok, record}
  end

  defp notify_about_deer_files_deletion(subscription_id, count, kilobytes) do
    GenServer.cast(SubscriptionStorageCache, {:removed_files, subscription_id, count, kilobytes})
  end
end
