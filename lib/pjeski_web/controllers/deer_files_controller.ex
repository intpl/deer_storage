defmodule PjeskiWeb.DeerFilesController do
  use PjeskiWeb, :controller

  def upload_for_record(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"record_id" => record_id, "file" => %Plug.Upload{filename: filename, path: path}}) do
    Pjeski.Services.UploadDeerFile.run!(path, filename, record_id, user.id)

    conn |> send_resp(200, "")
  end
end
