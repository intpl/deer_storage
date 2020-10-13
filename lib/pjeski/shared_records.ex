defmodule Pjeski.SharedRecords do
  import Ecto.Query, warn: false
  alias Pjeski.Repo
  alias Pjeski.SharedRecords.SharedRecord

  def get_record!(subscription_id, uuid) do
    Repo.one!(
      available_query()
      |> where([sr], sr.id == ^uuid)
      |> where([sr], sr.subscription_id == ^subscription_id)
    )
  end

  def create_record!(subscription_id, user_id, deer_record_id) do
    # TODO: track limits: user shared records per day e.g. 100
    Repo.insert!(
      SharedRecord.changeset(%SharedRecord{}, %{
            subscription_id: subscription_id,
            created_by_user_id: user_id,
            deer_record_id: deer_record_id}
      )
    )
  end

  def delete_outdated!, do: Repo.delete_all(outdated_query())

  defp available_query, do: from sr in SharedRecord, where: ^DateTime.utc_now < sr.expires_on
  defp outdated_query, do: from sr in SharedRecord, where: ^DateTime.utc_now >= sr.expires_on
end