defmodule Pjeski.Services.UploadDeerFile do
  defstruct [:tmp_path, :record, :original_filename, :subscription, :subscription_id, :uploaded_by_user_id, :md5sum, :kilobytes]

  import Ecto.Query, warn: false
  alias Pjeski.Repo

  import Pjeski.DeerRecords, only: [get_record!: 1, prepend_record_with_deer_file: 2]
  import Pjeski.Users, only: [ensure_user_subscription_link!: 2]

  def run!(tmp_path, original_filename, record_id, user_id) do
    record = get_record!(String.to_integer(record_id)) |> Repo.preload(:subscription)
    assigns = %__MODULE__{tmp_path: tmp_path, record: record, original_filename: original_filename, subscription: record.subscription, subscription_id: record.subscription.id, uploaded_by_user_id: user_id}

    assigns
    |> ensure_user_subscription_link!
    |> ensure_available_space_for_subscription
    |> calculate_md5sum
    |> ensure_md5sum_uniqueness
    |> copy_file!
    |> notify_subscription_storage_cache
    |> update_record
  end

  defp ensure_user_subscription_link!(%{uploaded_by_user_id: user_id, subscription_id: subscription_id} = assigns) do
    ensure_user_subscription_link!(user_id, subscription_id)

    assigns
  end

  defp ensure_available_space_for_subscription(todo), do: todo

  defp calculate_md5sum(%{tmp_path: tmp_path} = assigns) do
    {:ok, content} = File.read tmp_path
    md5sum = :crypto.hash(:md5, content) |> Base.encode16

    Map.merge(assigns, %{md5sum: md5sum})
  end

  defp ensure_md5sum_uniqueness(%{record: record, md5sum: md5sum} = assigns) do
    existing_md5sums = record.deer_files |> Enum.map(fn df -> df.md5sum end)
    case Enum.member?(existing_md5sums, md5sum) do
      true -> {:error, "file is already assigned"}
      false -> assigns
    end
  end

  defp copy_file!(%{tmp_path: tmp_path, md5sum: md5sum, subscription_id: subscription_id, record: %{id: record_id}} = assigns) do
    dir_path = File.cwd! <> "/uploaded_files/#{subscription_id}/#{record_id}"
    File.mkdir_p!(dir_path)

    dest_path = dir_path <> "/#{md5sum}"
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
