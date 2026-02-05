defmodule DeerStorage.SharedFiles do
  import Ecto.Query, warn: false

  alias DeerStorage.Repo
  alias DeerStorage.SharedFiles.SharedFile

  def get_file!(subscription_id, uuid, deer_file_id) do
    Repo.one!(
      available_query()
      |> where([sr], sr.id == ^uuid)
      |> where([sr], sr.subscription_id == ^subscription_id)
      |> where([sr], sr.deer_file_id == ^deer_file_id)
    )
  end

  def create_file!(subscription_id, user_id, deer_record_id, deer_file_id) do
    # TODO: track limits: user shared records per day e.g. 100
    Repo.insert!(
      SharedFile.changeset(%SharedFile{}, %{
        subscription_id: subscription_id,
        created_by_user_id: user_id,
        deer_record_id: deer_record_id,
        deer_file_id: deer_file_id
      })
    )
  end

  def delete_all_by_deer_record_id!(subscription_id, deer_record_id) do
    SharedFile
    |> where([sr], sr.subscription_id == ^subscription_id)
    |> where([sr], sr.deer_record_id == ^deer_record_id)
    |> Repo.delete_all()
  end

  def delete_outdated!, do: Repo.delete_all(outdated_query())

  defp available_query, do: from(sr in SharedFile, where: ^DateTime.utc_now() < sr.expires_on)
  defp outdated_query, do: from(sr in SharedFile, where: ^DateTime.utc_now() >= sr.expires_on)
end
