defmodule DeerStorage.Subscriptions do
  require Logger
  import Ecto.Query, warn: false
  alias Phoenix.PubSub
  alias DeerStorage.Repo
  alias DeerCache.RecordsCountsCache

  alias DeerCache.SubscriptionStorageCache
  alias DeerStorage.Subscriptions.Subscription
  alias DeerStorage.Subscriptions.DeerTable
  alias DeerStorage.DeerRecords
  alias DeerStorage.DeerRecords.DeerRecord

  import DeerStorage.Subscriptions.Helpers
  import DeerStorage.DbHelpers.ComposeSearchQuery

  import DeerRecord, only: [deer_files_stats: 1]

  def total_count(), do: DeerStorage.Repo.aggregate(from(s in "subscriptions"), :count, :id)

  def list_subscriptions("", page, per_page, sort_by) when page > 0 do
    offset = (page - 1) * per_page

    Subscription
    |> sort_subscriptions_by(sort_by)
    |> offset(^offset)
    |> limit(^per_page)
    |> Repo.all()
    |> Repo.preload(:users)
  end

  def list_subscriptions(query_string, page, per_page, sort_by) when page > 0 do
    offset = (page - 1) * per_page

    Subscription
    |> sort_subscriptions_by(sort_by)
    |> where(^compose_search_query([:name, :admin_notes], query_string))
    |> offset(^offset)
    |> limit(^per_page)
    |> Repo.all()
    |> Repo.preload(:users)
  end

  def list_subscriptions do
    Subscription
    |> Repo.all()
    |> Repo.preload(:users)
  end

  def list_subscriptions_except_ids(ids) do
    Subscription |> where([s], s.id not in ^ids) |> Repo.all()
  end

  def list_expired_subscriptions do
    date = Date.utc_today()
    query = from s in Subscription, where: fragment("?::date", s.expires_on) <= ^date

    query
    |> Repo.all()
    |> Repo.preload(:users)
  end

  # TODO: why bang then?
  def get_subscription!(nil), do: nil

  def get_subscription!(id) do
    Subscription
    |> Repo.get!(id)
    |> Repo.preload(:users)
  end

  def admin_create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.admin_changeset(attrs)
    |> Repo.insert()
  end

  def create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  def admin_update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.admin_changeset(attrs)
    |> Repo.update()
    |> maybe_notify_about_updated_subscription
  end

  def create_deer_tables!(old_subscription, tables) do
    subscription =
      Enum.reduce(tables, change_subscription_deer(old_subscription), fn {name, columns},
                                                                         subscription_acc ->
        Subscription.append_table(subscription_acc, name, columns)
      end)

    subscription
    |> Repo.update()
    |> maybe_notify_about_updated_subscription
  end

  def create_deer_table!(subscription, name, columns) do
    Subscription.append_table(change_subscription_deer(subscription), name, columns)
    |> Repo.update()
    |> maybe_notify_about_updated_subscription
  end

  def update_deer_table!(subscription, table_id, attrs) do
    deer_tables =
      subscription.deer_tables
      |> deer_tables_to_attrs
      |> overwrite_table_with_attrs(table_id, attrs)

    change_subscription_deer(subscription)
    |> Ecto.Changeset.cast(%{deer_tables: deer_tables}, [])
    |> Ecto.Changeset.cast_embed(:deer_tables,
      with: fn changeset, params ->
        DeerTable.ensure_no_columns_are_missing_changeset(changeset, params,
          subscription: subscription
        )
      end
    )
    |> Repo.update()
    |> maybe_notify_about_updated_subscription
  end

  def delete_deer_table(subscription, table_id) do
    case DeerRecords.at_least_one_record_with_table_id?(subscription, table_id) do
      true ->
        {:error, subscription}

      false ->
        delete_deer_table!(subscription, table_id)
        |> maybe_notify_about_updated_subscription
        |> maybe_delete_table_from_cache(table_id)
    end
  end

  def destroy_table_with_data!(%{id: subscription_id}, table_id) do
    records_query =
      from dr in DeerRecord,
        where: dr.deer_table_id == ^table_id and dr.subscription_id == ^subscription_id

    records_with_files_query =
      records_query |> where([r], fragment("cardinality(?) > 0", field(r, :deer_files)))

    {:ok, _result} =
      Repo.transaction(
        fn ->
          subscription =
            Repo.one!(from s in Subscription, where: s.id == ^subscription_id, lock: "FOR UPDATE")

          records_with_files = Repo.all(records_with_files_query, lock: "FOR UPDATE")

          delete_deer_table!(subscription, table_id)
          |> maybe_notify_about_updated_subscription
          |> maybe_delete_table_records!(records_query)
          |> maybe_delete_deer_table_directory!(subscription_id, table_id)
          |> maybe_substract_table_from_cache(subscription_id, table_id, records_with_files)
          |> maybe_delete_table_from_cache(table_id)
        end,
        # 5 minutes
        timeout: 300_000
      )
  end

  # this is used only in tests and seeds
  def update_subscription_deer(%Subscription{} = subscription, attrs) do
    subscription |> Subscription.deer_changeset(attrs) |> Repo.update()
  end

  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
    |> maybe_notify_about_updated_subscription
  end

  def delete_subscription(%Subscription{} = subscription) do
    subscription = Repo.delete!(subscription)
    File.rm_rf!(File.cwd!() <> "/uploaded_files/#{subscription.id}")

    Enum.each(subscription.deer_tables, fn %{id: table_id} ->
      delete_table_from_cache(table_id)
    end)

    {:ok, subscription}
  end

  def change_subscription_deer(%Subscription{} = subscription) do
    Subscription.deer_changeset(subscription, %{})
  end

  def change_subscription(%Subscription{} = subscription) do
    Subscription.changeset(subscription, %{})
  end

  def admin_change_subscription(%Subscription{} = subscription) do
    Subscription.admin_changeset(subscription, %{})
  end

  defp maybe_notify_about_updated_subscription({:error, _} = response), do: response

  defp maybe_notify_about_updated_subscription({:ok, subscription}) do
    PubSub.broadcast(
      DeerStorage.PubSub,
      "subscription:#{subscription.id}",
      {:subscription_updated, subscription}
    )

    {:ok, subscription}
  end

  defp maybe_delete_table_from_cache({:ok, _} = response, table_id) do
    delete_table_from_cache(table_id)
    response
  end

  defp maybe_delete_table_from_cache(error, _table_id), do: error

  defp delete_table_from_cache(table_id),
    do: GenServer.call(RecordsCountsCache, {:deleted_table, table_id})

  defp sort_subscriptions_by(q, ""), do: q
  defp sort_subscriptions_by(q, "name_desc"), do: q |> order_by(desc: :name)
  defp sort_subscriptions_by(q, "name_asc"), do: q |> order_by(asc: :name)
  defp sort_subscriptions_by(q, "expires_on_desc"), do: q |> order_by(desc: :expires_on)
  defp sort_subscriptions_by(q, "expires_on_asc"), do: q |> order_by(asc: :expires_on)
  defp sort_subscriptions_by(q, "files_limit_desc"), do: q |> order_by(desc: :deer_files_limit)
  defp sort_subscriptions_by(q, "files_limit_asc"), do: q |> order_by(asc: :deer_files_limit)
  defp sort_subscriptions_by(q, "tables_limit_desc"), do: q |> order_by(desc: :deer_tables_limit)
  defp sort_subscriptions_by(q, "tables_limit_asc"), do: q |> order_by(asc: :deer_tables_limit)

  defp sort_subscriptions_by(q, "columns_per_table_limit_desc"),
    do: q |> order_by(desc: :deer_columns_per_table_limit)

  defp sort_subscriptions_by(q, "columns_per_table_limit_asc"),
    do: q |> order_by(asc: :deer_columns_per_table_limit)

  defp sort_subscriptions_by(q, "records_per_table_limit_desc"),
    do: q |> order_by(desc: :deer_records_per_table_limit)

  defp sort_subscriptions_by(q, "records_per_table_limit_asc"),
    do: q |> order_by(asc: :deer_records_per_table_limit)

  defp sort_subscriptions_by(q, "storage_limit_kilobytes_desc"),
    do: q |> order_by(desc: :storage_limit_kilobytes)

  defp sort_subscriptions_by(q, "storage_limit_kilobytes_asc"),
    do: q |> order_by(asc: :storage_limit_kilobytes)

  defp sort_subscriptions_by(q, "admin_notes_desc"),
    do: q |> order_by(desc_nulls_last: :admin_notes)

  defp sort_subscriptions_by(q, "admin_notes_asc"),
    do: q |> order_by(asc_nulls_first: :admin_notes)

  defp sort_subscriptions_by(q, "inserted_at_desc"), do: q |> order_by(desc: :inserted_at)
  defp sort_subscriptions_by(q, "inserted_at_asc"), do: q |> order_by(asc: :inserted_at)
  defp sort_subscriptions_by(q, "updated_at_desc"), do: q |> order_by(desc: :updated_at)
  defp sort_subscriptions_by(q, "updated_at_asc"), do: q |> order_by(asc: :updated_at)

  defp sort_subscriptions_by(q, "users_count_desc") do
    from s in q,
      left_join: u in assoc(s, :users),
      order_by: [desc: count(u.id)],
      group_by: s.id
  end

  defp sort_subscriptions_by(q, "users_count_asc") do
    from s in q,
      left_join: u in assoc(s, :users),
      order_by: [asc: count(u.id)],
      group_by: s.id
  end

  defp maybe_delete_table_records!({:error, error_message} = response, _records_query) do
    Logger.error(error_message)

    response
  end

  defp maybe_delete_table_records!({:ok, _} = response, records_query) do
    {_count, _} = Repo.delete_all(records_query)

    response
  end

  defp maybe_delete_deer_table_directory!(
         {:error, error_message} = response,
         _subscription_id,
         _table_id
       ) do
    Logger.error(error_message)

    response
  end

  defp maybe_delete_deer_table_directory!({:ok, _} = response, subscription_id, table_id) do
    File.rm_rf!(File.cwd!() <> "/uploaded_files/#{subscription_id}/#{table_id}")

    response
  end

  defp maybe_substract_table_from_cache(
         {:error, error_message} = response,
         _subscription_id,
         _table_id,
         _records
       ) do
    Logger.error(error_message)

    response
  end

  defp maybe_substract_table_from_cache({:ok, _} = response, subscription_id, table_id, records) do
    [table_files_count, table_kilobytes] =
      Enum.reduce(records, [0, 0], fn %{
                                        subscription_id: ^subscription_id,
                                        deer_table_id: ^table_id
                                      } = dr,
                                      [total_files, total_kilobytes] ->
        {dr_files, dr_kilobytes} = deer_files_stats(dr)
        [total_files + dr_files, total_kilobytes + dr_kilobytes]
      end)

    GenServer.cast(
      SubscriptionStorageCache,
      {:removed_files, subscription_id, table_files_count, table_kilobytes}
    )

    response
  end

  defp delete_deer_table!(subscription, table_id) do
    deer_tables =
      subscription.deer_tables
      |> deer_tables_to_attrs
      |> Enum.reject(fn dt -> dt.id == table_id end)

    change_subscription_deer(subscription)
    |> Ecto.Changeset.cast(%{deer_tables: deer_tables}, [])
    |> Ecto.Changeset.cast_embed(:deer_tables)
    |> Repo.update()
  end
end
