defmodule Pjeski.DeerRecords do
  import Ecto.Query, warn: false
  alias Pjeski.Repo

  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.Subscriptions.Subscription

  def list_records(%Subscription{id: subscription_id}) do
    DeerRecord
    |> where(subscription_id: ^subscription_id)
    |> Repo.all()
  end

  def get_record!(id, %Subscription{id: subscription_id}) do
    DeerRecord
    |> Repo.get_by!(id: id, subscription_id: subscription_id)
  end

  def create_record(attrs, %Subscription{} = subscription) do
    %DeerRecord{subscription_id: subscription.id} |> DeerRecord.changeset(attrs, subscription) |> Repo.insert()
  end

  def update_record(%DeerRecord{} = record, attrs, %Subscription{} = subscription) do
    record
    |> DeerRecord.changeset(attrs, subscription)
    |> Repo.update()
  end

  def change_record(%DeerRecord{} = record, %Subscription{} = subscription) do
    DeerRecord.changeset(record, %{}, subscription)
  end
end
