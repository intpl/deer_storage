defmodule PjeskiWeb.SharedRecordFilesController do
  use PjeskiWeb, :controller

  alias Pjeski.SharedRecords
  import Pjeski.DeerRecords, only: [ensure_deer_file_exists_in_record!: 2]

  def download_file(conn, %{"subscription_id" => subscription_id, "shared_record_id" => shared_record_id, "file_id" => file_id}) do
    shared_record = SharedRecords.get_record!(subscription_id, shared_record_id) |> Pjeski.Repo.preload(:deer_record)
    deer_record = shared_record.deer_record
    deer_file = ensure_deer_file_exists_in_record!(deer_record, file_id)

    file_path = File.cwd! <> "/uploaded_files/#{subscription_id}/#{deer_record.deer_table_id}/#{deer_record.id}/#{deer_file.id}"

    send_download(conn, {:file, file_path}, filename: deer_file.original_filename)
  end
end
