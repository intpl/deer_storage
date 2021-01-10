defmodule Pjeski.Services.UploadDeerFile do
  defstruct [:caller_pid, :tmp_path, :record, :original_filename, :subscription, :subscription_id, :uploaded_by_user_id, :id, :kilobytes]

  import Ecto.Query, warn: false
  alias Pjeski.Repo

  alias Pjeski.DeerRecords.DeerRecord

  import Pjeski.DeerRecords, only: [prepend_record_with_deer_file!: 2]
  import Pjeski.Users, only: [ensure_user_subscription_link!: 2]
  import PjeskiWeb.LiveHelpers, only: [is_expired?: 1]

  def run!(pid, tmp_path, original_filename, record_id, user_id, id) do
    {:ok, inside_transaction_result} = Repo.transaction(fn ->
      record = Repo.one!(from(dr in DeerRecord, where: dr.id == ^record_id, lock: "FOR UPDATE")) |> Repo.preload(:subscription)
      assigns = %__MODULE__{caller_pid: pid, tmp_path: tmp_path, record: record, original_filename: original_filename, subscription: record.subscription, subscription_id: record.subscription.id, uploaded_by_user_id: user_id, id: id}

      assigns
      |> raise_if_subscription_is_expired
      |> ensure_user_subscription_link_from_assigns!
      |> validate_maximum_filename_length
      |> ensure_limits_for_subscription
      |> copy_file!
      |> notify_subscription_storage_cache # this may be wrong if update_record raises error
      |> update_record
    end)

    GenServer.cast(pid, {:upload_deer_file_result, {original_filename, inside_transaction_result}})
  after
    File.rm!(tmp_path)
  end

  defp raise_if_subscription_is_expired(%{subscription: subscription} = assigns) do
    if is_expired?(subscription), do: raise "Subscription is expired"

    assigns
  end

  defp ensure_user_subscription_link_from_assigns!(%{uploaded_by_user_id: user_id, subscription_id: subscription_id} = assigns) do
    ensure_user_subscription_link!(user_id, subscription_id)

    assigns
  end

  defp validate_maximum_filename_length(%{original_filename: filename} = assigns) do
    if String.length(filename) < 256, do: assigns, else: raise "filename length is more than maximum 255 characters"
  end

  defp ensure_limits_for_subscription(%{tmp_path: tmp_path, subscription: %{id: subscription_id, storage_limit_kilobytes: storage_limit_kilobytes, deer_files_limit: deer_files_limit}} = assigns) do
    %File.Stat{size: filesize_bytes} = File.stat!(tmp_path)
    filesize_kilobytes = ceil(filesize_bytes/1024)
    {files_count, used_storage_kilobytes} = DeerCache.SubscriptionStorageCache.fetch_data(subscription_id)

    if (storage_limit_kilobytes - used_storage_kilobytes) > filesize_kilobytes && files_count < deer_files_limit do
      Map.merge(assigns, %{kilobytes: filesize_kilobytes})
    else
      {name, _arity} = __ENV__.function

      {:error, name}
    end
  end

  defp copy_file!({:error, _} = result), do: result
  defp copy_file!(%{tmp_path: tmp_path, id: id, subscription_id: subscription_id, record: %{id: record_id, deer_table_id: table_id}} = assigns) do
    dir_path = File.cwd! <> "/uploaded_files/#{subscription_id}/#{table_id}/#{record_id}"

    File.mkdir_p!(dir_path)
    File.cp!(tmp_path, dir_path <> "/#{id}")

    assigns
  end

  defp notify_subscription_storage_cache({:error, _} = result), do: result
  defp notify_subscription_storage_cache(%{subscription: %{id: subscription_id}, kilobytes: kilobytes} = assigns) do
    GenServer.cast(DeerCache.SubscriptionStorageCache, {:uploaded_file, subscription_id, kilobytes})

    assigns
  end

  defp update_record({:error, _} = result), do: result
  defp update_record(%{record: record} = assigns) do
    {:ok, _record} = prepend_record_with_deer_file!(record, Map.from_struct(assigns))
  end
end
