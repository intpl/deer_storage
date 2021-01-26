defmodule PjeskiWeb.LocalePlugTest do
  use PjeskiWeb.ConnCase
  import Pjeski.Fixtures
  import Pjeski.Test.SessionHelpers, only: [assign_locale_to_session: 2, assign_user_to_session: 2]

  describe "when the is no header and no session" do
    test "it puts default locale" do
      conn = Phoenix.ConnTest.build_conn(:get, "/") |> get("/")
      assert html_response(conn, 200) =~ "Welcome to DeerStorage"
    end
  end
  describe "when the accept-language header is \"pl\" and there is no locale in session" do
    test "it puts \"pl\" locale" do
      conn = Phoenix.ConnTest.build_conn(:get, "/") |> Plug.Conn.put_req_header("accept-language", "pl-PL, pl;q=0.8, nl;q=0.9, en;q=0.7") |> get("/")

      assert html_response(conn, 200) =~ "Witamy w DeerStorage"
    end
  end
  describe "when the accept-language header is invalid and there is no locale in session" do
    test "it puts default locale" do
      conn = Phoenix.ConnTest.build_conn(:get, "/") |> Plug.Conn.put_req_header("accept-language", "INVALID 123, 2, 2") |> get("/")

      assert html_response(conn, 200) =~ "Welcome to DeerStorage"
    end
  end
  describe "when there is a locale in session" do
    test "when the locale in session is an unsupported locale, it should use the default locale" do
      conn = Phoenix.ConnTest.build_conn(:get, "/") |> assign_locale_to_session("ar") |> get("/")

      assert html_response(conn, 200) =~ "Welcome to DeerStorage"
    end

    test "when is available -> puts locale in assigns" do
      conn = Phoenix.ConnTest.build_conn(:get, "/") |> assign_locale_to_session("pl") |> get("/")

      assert html_response(conn, 200) =~ "Witamy w DeerStorage"
    end

    test "when headers contain accept-language, it should set locale in session" do
      conn = Phoenix.ConnTest.build_conn(:get, "/")
        |> assign_locale_to_session("pl")
        |> Plug.Conn.put_req_header("accept-language", "de, en-gb;q=0.8, en;q=0.7")
        |> get("/")

      assert html_response(conn, 200) =~ "Witamy w DeerStorage"
    end
  end
  describe "when user is logged in" do
    test "it should set user locale even there was one set before" do
      conn = Phoenix.ConnTest.build_conn(:get, "/") |> assign_locale_to_session("en") |> get("/")
      assert html_response(conn, 200) =~ "Welcome to DeerStorage"

      user = create_valid_user_with_subscription() # user is polish by default
      conn = assign_user_to_session(recycle(conn), user) |> get("/")
      assert html_response(conn, 200) =~ "Witamy w DeerStorage"
    end
  end
end
