defmodule DeerStorage.SharedRecords do
  import Ecto.Query, warn: false

  alias Phoenix.PubSub
  alias DeerStorage.Repo
  alias DeerStorage.SharedRecords.SharedRecord

  def get_record!(subscription_id, uuid) do
    Repo.one!(
      available_query()
      |> where([sr], sr.id == ^uuid)
      |> where([sr], sr.subscription_id == ^subscription_id)
    )
  end

  def create_record!(subscription_id, user_id, deer_record_id) do
    do_create!(subscription_id, user_id, deer_record_id, false)
  end

  def create_record_for_editing!(subscription_id, user_id, deer_record_id) do
    do_create!(subscription_id, user_id, deer_record_id, true)
  end

  def delete_all_by_deer_record_id!(subscription_id, deer_record_id) do
    SharedRecord
    |> where([sr], sr.subscription_id == ^subscription_id)
    |> where([sr], sr.deer_record_id == ^deer_record_id)
    |> Repo.delete_all()

    PubSub.broadcast DeerStorage.PubSub, "shared_records_invalidates:#{deer_record_id}", :all_shared_records_invalidated
  end

  def delete_outdated!, do: Repo.delete_all(outdated_query())

  defp do_create!(subscription_id, user_id, deer_record_id, is_editable) do
    # TODO: track limits: user shared records per day e.g. 100
    Repo.insert!(
      SharedRecord.changeset(%SharedRecord{}, %{
            subscription_id: subscription_id,
            created_by_user_id: user_id,
            deer_record_id: deer_record_id,
            is_editable: is_editable}))
  end

  defp available_query, do: from sr in SharedRecord, where: ^DateTime.utc_now < sr.expires_on
  defp outdated_query, do: from sr in SharedRecord, where: ^DateTime.utc_now >= sr.expires_on
end
