defmodule PjeskiWeb.DeerFilesController do
  use PjeskiWeb, :controller

  import Pjeski.DeerRecords, only: [get_record!: 1, ensure_deer_file_exists_in_record!: 2]
  import Pjeski.Users, only: [ensure_user_subscription_link!: 2]

  def upload_for_record(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"record_id" => record_id, "file" => %Plug.Upload{filename: filename, path: path}}) do
    case Pjeski.Services.UploadDeerFile.run!(path, filename, record_id, user.id) do
      {:error, key} ->
        send_resp(conn, 403, translate_error(key))
      _ -> send_resp(conn, 200, "")
    end
  end

  def download_record(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"record_id" => record_id, "file_id" => file_id}) do
    record = get_record!(record_id) |> Pjeski.Repo.preload(:subscription)
    subscription_id = record.subscription.id # TODO: check if not expired

    ensure_user_subscription_link!(user.id, subscription_id)

    deer_file = ensure_deer_file_exists_in_record!(record, file_id)

    file_path = File.cwd! <> "/uploaded_files/#{subscription_id}/#{record_id}/#{deer_file.id}"

    send_download(conn, {:file, file_path}, filename: deer_file.original_filename)
  end

  defp translate_error(:ensure_limits_for_subscription), do: gettext("This subscription limits has been met")
end
