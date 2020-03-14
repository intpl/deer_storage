defmodule PjeskiWeb.PageControllerTest do
  use PjeskiWeb.ConnCase

  test "GET /", %{guest_conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "StorageDeer"
  end
end
