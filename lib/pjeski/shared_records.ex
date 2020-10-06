defmodule Pjeski.SharedRecords do
  import Ecto.Query, warn: false
  alias Pjeski.Repo
  alias Pjeski.SharedRecords.SharedRecord

  def get_record!(uuid), do: Repo.get!(SharedRecord, uuid)

  def create_record!(subscription_id, user_id, deer_record_id) do
    Repo.insert!(
      SharedRecord.changeset(%SharedRecord{}, %{
            subscription_id: subscription_id,
            created_by_user_id: user_id,
            deer_record_id: deer_record_id}
      )
    )
  end
end
