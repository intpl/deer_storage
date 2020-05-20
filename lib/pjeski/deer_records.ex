defmodule Pjeski.DeerRecords do
  import Ecto.Query, warn: false
  alias Pjeski.Repo

  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.Subscriptions.Subscription

  defmacro per_page, do: 30
  defp offset(page) when page > 0, do: (page - 1) * per_page()

  def list_records(%Subscription{id: subscription_id}, table_id) do
    DeerRecord
    |> where(subscription_id: ^subscription_id, deer_table_id: ^table_id)
    |> Repo.all()
  end

  def get_record!(%Subscription{id: subscription_id}, id) do
    DeerRecord
    |> Repo.get_by!(id: id, subscription_id: subscription_id)
  end

  def create_record(%Subscription{} = subscription, attrs) do
    %DeerRecord{subscription_id: subscription.id} |> DeerRecord.changeset(attrs, subscription) |> Repo.insert()
  end

  def update_record(%Subscription{} = subscription, %DeerRecord{} = record, attrs) do
    record
    |> DeerRecord.changeset(attrs, subscription)
    |> Repo.update()
  end

  def change_record(%Subscription{} = subscription, %DeerRecord{} = record, attrs) do
    DeerRecord.changeset(record, attrs, subscription)
  end

  def delete_record(%Subscription{id: subscription_id}, %DeerRecord{subscription_id: subscription_id} = record) do
    Repo.delete(record)
  end
end
