defmodule PjeskiWeb.ControllerHelpers.FileHelpers do
  import Phoenix.Controller, only: [send_download: 3]
  import Plug.Conn, only: [put_resp_header: 3]

  def send_download_with_range_headers(conn, file_path, deer_file) do
    conn
    |> put_resp_header("Content-Type", deer_file.mimetype)
    |> put_resp_header("Accept-Ranges", "bytes")
    |> send_download({:file, file_path}, filename: deer_file.original_filename)
  end
end
