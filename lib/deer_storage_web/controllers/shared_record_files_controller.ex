defmodule DeerStorageWeb.SharedRecordFilesController do
  use DeerStorageWeb, :controller

  alias DeerStorage.SharedRecords
  alias DeerStorage.SharedFiles
  import DeerStorageWeb.LiveHelpers, only: [is_expired?: 1]
  import DeerStorage.DeerRecords, only: [ensure_deer_file_exists_in_record!: 2]
  import DeerStorageWeb.ControllerHelpers.FileHelpers

  def download_file_from_shared_file(conn, %{
        "subscription_id" => subscription_id,
        "shared_file_id" => shared_file_id,
        "file_id" => file_id
      }) do
    shared_file =
      SharedFiles.get_file!(subscription_id, shared_file_id, file_id)
      |> DeerStorage.Repo.preload([:deer_record, :subscription])

    deer_record = shared_file.deer_record

    if is_expired?(shared_file.subscription), do: raise("Subscription is expired")
    # TODO OR show error
    deer_file = ensure_deer_file_exists_in_record!(deer_record, file_id)

    file_path =
      File.cwd!() <>
        "/uploaded_files/#{subscription_id}/#{deer_record.deer_table_id}/#{deer_record.id}/#{deer_file.id}"

    send_download_with_range_headers(conn, file_path, deer_file)
  rescue
    _ -> {:noreply, conn |> put_flash(:error, "Could not find file.") |> redirect(to: "/")}
  end

  def download_file_from_shared_record(conn, %{
        "subscription_id" => subscription_id,
        "shared_record_id" => shared_record_id,
        "file_id" => file_id
      }) do
    shared_record =
      SharedRecords.get_record!(subscription_id, shared_record_id)
      |> DeerStorage.Repo.preload([:deer_record, :subscription])

    deer_record = shared_record.deer_record
    if is_expired?(shared_record.subscription), do: raise("Subscription is expired")

    deer_file = ensure_deer_file_exists_in_record!(deer_record, file_id)

    file_path =
      File.cwd!() <>
        "/uploaded_files/#{subscription_id}/#{deer_record.deer_table_id}/#{deer_record.id}/#{deer_file.id}"

    send_download_with_range_headers(conn, file_path, deer_file)
  rescue
    _ -> {:noreply, conn |> put_flash(:error, "Could not find record.") |> redirect(to: "/")}
  end
end
