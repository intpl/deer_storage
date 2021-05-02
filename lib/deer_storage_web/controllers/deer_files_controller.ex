defmodule DeerStorageWeb.DeerFilesController do
  use DeerStorageWeb, :controller

  import DeerStorageWeb.LiveHelpers, only: [is_expired?: 1]
  import DeerStorage.DeerRecords, only: [get_record!: 1, ensure_deer_file_exists_in_record!: 2]
  import DeerStorage.Users, only: [ensure_user_subscription_link!: 2]
  import DeerStorageWeb.ControllerHelpers.FileHelpers

  def download_record(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"record_id" => record_id, "file_id" => file_id}) do
    record = get_record!(record_id) |> DeerStorage.Repo.preload(:subscription)
    subscription_id = record.subscription.id

    if is_expired?(record.subscription), do: raise "Subscription is expired"
    ensure_user_subscription_link!(user.id, subscription_id)

    deer_file = ensure_deer_file_exists_in_record!(record, file_id)

    file_path = File.cwd! <> "/uploaded_files/#{subscription_id}/#{record.deer_table_id}/#{record.id}/#{deer_file.id}"

    send_download_with_range_headers(conn, file_path, deer_file)
  end
end
