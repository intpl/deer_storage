defmodule PjeskiWeb.PageControllerTest do
  use PjeskiWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "System Zarządzania Kliniką"
  end
end
