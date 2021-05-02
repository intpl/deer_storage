defmodule DeerStorageWeb.PageControllerTest do
  use DeerStorageWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "DeerStorage"
  end
end
