defmodule Pjeski.DeerRecords do
  import Ecto.Query, warn: false
  alias Phoenix.PubSub
  alias Pjeski.Repo
  alias DeerCache.RecordsCountsCache

  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.Subscriptions.Subscription

  def at_least_one_record_with_table_id?(%Subscription{id: subscription_id}, table_id) do
    query = DeerRecord
    |> where([dr], dr.subscription_id == ^subscription_id)
    |> where([dr], dr.deer_table_id == ^table_id)
    |> limit(1)

    !!Repo.one(query)
  end

  def get_record!(id), do: Repo.get!(DeerRecord, id)
  def get_record!(%Subscription{id: subscription_id}, id) do
    DeerRecord
    |> Repo.get_by!(id: id, subscription_id: subscription_id)
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
  end

  def batch_delete_records(%Subscription{id: subscription_id}, table_id, list_of_ids) do
    {deleted_count, _} = DeerRecord
    |> where([dr], dr.subscription_id == ^subscription_id)
    |> where([dr], dr.deer_table_id == ^table_id)
    |> where([dr], dr.id in ^list_of_ids)
    |> Repo.delete_all

    notify_about_batch_record_delete(subscription_id, table_id, list_of_ids)
    decrement_deer_cache(table_id, deleted_count)

    {:ok, deleted_count}
  end

  def count_records_grouped_by_deer_table_id do
    Repo.all(
      from r in DeerRecord,
      group_by: r.deer_table_id,
      select: %{deer_table_id: r.deer_table_id, count: count(r.id)}
    )
  end

  def prepend_record_with_deer_file(record, deer_file) do
    record
    |> DeerRecord.prepend_deer_file_to_changeset(deer_file)
    |> Repo.update()
    |> maybe_notify_about_record_update
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
    PubSub.broadcast(Pjeski.PubSub,
      "record:#{record.subscription_id}:#{record.deer_table_id}",
      {:record_delete, record.id}
    )

    {:ok, record}
  end

  defp notify_about_batch_record_delete(subscription_id, table_id, ids) do
    PubSub.broadcast(Pjeski.PubSub,
      "record:#{subscription_id}:#{table_id}",
      {:batch_record_delete, ids}
    )
  end

  defp maybe_notify_about_record_update({:error, _} = response), do: response
  defp maybe_notify_about_record_update({:ok, record}) do
    PubSub.broadcast(
      Pjeski.PubSub,
      "record:#{record.subscription_id}:#{record.deer_table_id}",
      {:record_update, record}
    )

    {:ok, record}
  end

  defp maybe_delete_deer_files_directory({:error, _} = response), do: response
  defp maybe_delete_deer_files_directory({:ok, record}) do
    File.rm_rf!(File.cwd! <> "/uploaded_files/#{record.subscription_id}/#{record.id}")

    {:ok, record}
  end
end
