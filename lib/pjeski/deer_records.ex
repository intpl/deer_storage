defmodule Pjeski.DeerRecords do
  import Ecto.Query, warn: false
  alias Phoenix.PubSub
  alias Pjeski.Repo
  alias DeerCache.RecordsCountsCache

  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.Subscriptions.Subscription

  def get_record!(%Subscription{id: subscription_id}, id) do
    DeerRecord
    |> Repo.get_by!(id: id, subscription_id: subscription_id)
  end

  def create_record(%Subscription{} = subscription, attrs) do
    %DeerRecord{subscription_id: subscription.id}
    |> DeerRecord.changeset(attrs, subscription)
    |> Repo.insert()
    |> maybe_notify_about_record_change
    |> maybe_increment_deer_cache
  end

  def update_record(%Subscription{} = subscription, %DeerRecord{} = record, attrs) do
    record
    |> DeerRecord.changeset(attrs, subscription)
    |> Repo.update()
    |> maybe_notify_about_record_change
  end

  def change_record(%Subscription{} = subscription, record, attrs) do
    DeerRecord.changeset(record, attrs, subscription)
  end

  def delete_record(%Subscription{id: subscription_id}, %DeerRecord{subscription_id: subscription_id} = record) do
    Repo.delete(record) |> maybe_notify_about_record_change |> maybe_decrement_deer_cache
  end

  def count_records_grouped_by_deer_table_id do
    Repo.all(
      from r in DeerRecord,
      group_by: r.deer_table_id,
      select: %{deer_table_id: r.deer_table_id, count: count(r.id)}
    )
  end

  defp maybe_decrement_deer_cache({:error, _} = response), do: response
  defp maybe_decrement_deer_cache({:ok, %{deer_table_id: table_id} = record}) do
    GenServer.cast(RecordsCountsCache, {:decrement, table_id})
    {:ok, record}
  end

  defp maybe_increment_deer_cache({:error, _} = response), do: response
  defp maybe_increment_deer_cache({:ok, %{deer_table_id: table_id} = record}) do
    GenServer.cast(RecordsCountsCache, {:increment, table_id})
    {:ok, record}
  end

  defp maybe_notify_about_record_change({:error, _} = response), do: response
  defp maybe_notify_about_record_change({:ok, record}) do
    PubSub.broadcast(
      Pjeski.PubSub,
      "record:#{record.subscription_id}:#{record.deer_table_id}",
      {:record_change, record}
    )

    {:ok, record}
  end
end
