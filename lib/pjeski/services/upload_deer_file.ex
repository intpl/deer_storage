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
      |> ensure_limits_for_subscription
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

  defp ensure_limits_for_subscription(%{tmp_path: tmp_path, subscription: %{id: subscription_id, storage_limit_kilobytes: storage_limit_kilobytes}} = assigns) do
    %File.Stat{size: filesize_bytes} = File.stat!(tmp_path)
    filesize_kilobytes = ceil(filesize_bytes/1024)
    {_files, used_storage_kilobytes} = DeerCache.SubscriptionStorageCache.fetch_data(subscription_id) # TODO files count

    if (storage_limit_kilobytes - used_storage_kilobytes) > filesize_kilobytes do
      Map.merge(assigns, %{kilobytes: filesize_kilobytes})
    else
      {name, _arity} = __ENV__.function

      {:error, name}
    end
  end

  defp generate_random_id(assigns) do
    id = :crypto.strong_rand_bytes(20) |> Base.url_encode64 |> binary_part(0, 20)

    Map.merge(assigns, %{id: id})
  end

  defp copy_file!(%{tmp_path: tmp_path, id: id, subscription_id: subscription_id, record: %{id: record_id}} = assigns) do
    dir_path = File.cwd! <> "/uploaded_files/#{subscription_id}/#{record_id}"

    File.mkdir_p!(dir_path)
    File.copy!(tmp_path, dir_path <> "/#{id}")

    assigns
  end

  defp notify_subscription_storage_cache(%{subscription: %{id: subscription_id}, kilobytes: kilobytes} = assigns) do
    GenServer.cast(DeerCache.SubscriptionStorageCache, {:uploaded_file, subscription_id, kilobytes})

    assigns
  end

  defp update_record(%{record: record} = assigns) do
    {:ok, _record} = prepend_record_with_deer_file(record, Map.from_struct(assigns))
  end
end
