defmodule PjeskiWeb.Admin.UserControllerTest do
  use PjeskiWeb.ConnCase

  alias Pjeski.Users

  @create_attrs %{email: "test@test.eu",
                  name: "Henryk Testowny",
                  password: "secret123",
                  password_confirmation: "secret123",
                  locale: "pl",
                  subscription: %{
                    name: "Test",
                    email: "test@example.org"
                  }
  }

  @update_attrs %{email: "test2@test.eu"}

  def fixture(:user) do
    {:ok, user} = Users.create_user(@create_attrs)
    user
  end

  describe "index" do
    setup [:create_user]

    test "lists all users", %{admin_conn: admin_conn} do
      conn = get(admin_conn, Routes.admin_user_path(admin_conn, :index))
      assert html_response(conn, 200) =~ "Użytkownicy"
      assert html_response(conn, 200) =~ "Henryk Testowny"
    end
  end

  describe "new user" do
    test "renders form", %{admin_conn: admin_conn} do
      conn = get(admin_conn, Routes.admin_user_path(admin_conn, :new))
      assert html_response(conn, 200) =~ "Nowy Użytkownik"
    end
  end

  describe "create user" do
    test "redirects to show when data is valid", %{admin_conn: admin_conn} do
      conn = post(admin_conn, Routes.admin_user_path(admin_conn, :create), user: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.admin_user_path(admin_conn, :show, id)

      conn = get(admin_conn, Routes.admin_user_path(admin_conn, :show, id))
      assert html_response(conn, 200) =~ "Henryk Testowny"
    end
  end

  describe "edit user" do
    setup [:create_user]

    test "renders form for editing chosen user", %{admin_conn: admin_conn, user: user} do
      conn = get(admin_conn, Routes.admin_user_path(admin_conn, :edit, user))
      assert html_response(conn, 200) =~ "Imię i nazwisko"
    end
  end

  describe "update user" do
    setup [:create_user]

    test "redirects when data is valid", %{admin_conn: admin_conn, user: user} do
      conn = put(admin_conn, Routes.admin_user_path(admin_conn, :update, user), user: @update_attrs)
      assert redirected_to(conn) == Routes.admin_user_path(admin_conn, :show, user)

      conn = get(admin_conn, Routes.admin_user_path(admin_conn, :show, user))
      assert html_response(conn, 200) =~ "test2@test.eu"
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{admin_conn: admin_conn, user: user} do
      conn = delete(admin_conn, Routes.admin_user_path(admin_conn, :delete, user))
      assert redirected_to(conn) == Routes.admin_user_path(admin_conn, :index)
      assert_error_sent 404, fn ->
        get(admin_conn, Routes.admin_user_path(conn, :show, user))
      end
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
