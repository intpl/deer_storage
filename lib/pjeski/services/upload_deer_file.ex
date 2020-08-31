defmodule Pjeski.Services.UploadDeerFile do
  defstruct [:tmp_path, :record, :original_filename, :subscription, :subscription_id, :uploaded_by_user_id, :id, :kilobytes]

  import Ecto.Query, warn: false
  alias Pjeski.Repo

  alias Pjeski.DeerRecords.DeerRecord

  import Pjeski.DeerRecords, only: [prepend_record_with_deer_file: 2]
  import Pjeski.Users, only: [ensure_user_subscription_link!: 2]

  def run!(tmp_path, original_filename, record_id, user_id) do
    Repo.transaction(fn ->
      record = Repo.one!(from(dr in DeerRecord, where: dr.id == ^record_id, lock: "FOR UPDATE")) |> Repo.preload(:subscription)
      assigns = %__MODULE__{tmp_path: tmp_path, record: record, original_filename: original_filename, subscription: record.subscription, subscription_id: record.subscription.id, uploaded_by_user_id: user_id}

      assigns
      |> ensure_user_subscription_link!
      |> ensure_available_space_for_subscription # you will need to lock subscription too
      |> generate_random_id
      |> copy_file!
      |> notify_subscription_storage_cache
      |> update_record
    end)
  end

  defp ensure_user_subscription_link!(%{uploaded_by_user_id: user_id, subscription_id: subscription_id} = assigns) do
    ensure_user_subscription_link!(user_id, subscription_id)

    assigns
  end

  defp ensure_available_space_for_subscription(todo), do: todo

  defp generate_random_id(assigns) do
    id = :crypto.strong_rand_bytes(20) |> Base.url_encode64 |> binary_part(0, 20)

    Map.merge(assigns, %{id: id})
  end

  defp copy_file!(%{tmp_path: tmp_path, id: id, subscription_id: subscription_id, record: %{id: record_id}} = assigns) do
    dir_path = File.cwd! <> "/uploaded_files/#{subscription_id}/#{record_id}"
    File.mkdir_p!(dir_path)

    dest_path = dir_path <> "/#{id}"
    # TODO: check if this file already exists
    {:ok, bytes_copied} = File.copy(tmp_path, dest_path)

    # TODO: move assignment to ensure_available_space_for_subscription
    Map.merge(assigns, %{kilobytes: ceil(bytes_copied/1024)})
  end

  defp notify_subscription_storage_cache(todo), do: todo

  defp update_record(%{record: record} = assigns) do
    {:ok, _record} = prepend_record_with_deer_file(record, Map.from_struct(assigns))
  end
end
