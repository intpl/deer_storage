defmodule PjeskiWeb.DeerFilesController do
  use PjeskiWeb, :controller

  import PjeskiWeb.LiveHelpers, only: [is_expired?: 1]
  import Pjeski.DeerRecords, only: [get_record!: 1, ensure_deer_file_exists_in_record!: 2]
  import Pjeski.Users, only: [ensure_user_subscription_link!: 2]

  def download_record(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"record_id" => record_id, "file_id" => file_id}) do
    record = get_record!(record_id) |> Pjeski.Repo.preload(:subscription)
    subscription_id = record.subscription.id

    if is_expired?(record.subscription), do: raise "Subscription is expired"
    ensure_user_subscription_link!(user.id, subscription_id)

    deer_file = ensure_deer_file_exists_in_record!(record, file_id)

    file_path = File.cwd! <> "/uploaded_files/#{subscription_id}/#{record.deer_table_id}/#{record.id}/#{deer_file.id}"

    send_download(conn, {:file, file_path}, filename: deer_file.original_filename)
  end
end
