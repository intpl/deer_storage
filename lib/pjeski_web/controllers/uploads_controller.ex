defmodule PjeskiWeb.UploadsController do
  use PjeskiWeb, :controller

  def upload_for_record(conn, %{"record_id" => record_id, "file" => file}) do
    require IEx; IEx.pry # FIXME
  end
end
