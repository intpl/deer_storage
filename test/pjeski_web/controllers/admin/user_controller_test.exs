defmodule PjeskiWeb.Admin.UserControllerTest do
  use PjeskiWeb.ConnCase

  alias Pjeski.Repo
  alias Pjeski.Users
  alias Pjeski.Users.User

  import Pjeski.Test.SessionHelpers, only: [assign_user_to_session: 2]

  @admin_attrs %{email: "admin@storagedeer.com",
                  name: "Admin",
                  password: "secret123",
                  password_confirmation: "secret123",
                  locale: "pl",
  }

  @create_attrs %{email: "test@test.eu",
                  name: "Henryk Testowny",
                  password: "secret123",
                  password_confirmation: "secret123",
                  locale: "pl",
                  last_used_subscription: %{
                    name: "Test",
                    email: "test@example.org"
                  }
  }

  @update_attrs %{email: "test2@test.eu"}

  def fixture(:user) do
    {:ok, user} = Users.create_user(@create_attrs)
    user
  end

  setup do
    {:ok, admin} = Users.admin_create_user(@admin_attrs |> Map.merge(%{role: "admin"}))
    {:ok, admin: admin}
  end

  describe "index" do
    test "lists all users", %{guest_conn: guest_conn, admin: admin} do
      fixture(:user)

      conn = assign_user_to_session(guest_conn, admin)
      conn = get(conn, Routes.admin_user_path(conn, :index))

      assert html_response(conn, 200) =~ "Użytkownicy"
      assert html_response(conn, 200) =~ "Henryk Testowny"
    end
  end

  describe "new user" do
    test "renders form", %{guest_conn: guest_conn, admin: admin} do
      conn = assign_user_to_session(guest_conn, admin)
      conn = get(conn, Routes.admin_user_path(conn, :new))

      assert html_response(conn, 200) =~ "Nowy Użytkownik"
    end
  end

  describe "create user" do
    test "redirects to show when data is valid", %{guest_conn: guest_conn, admin: admin} do
      conn = assign_user_to_session(guest_conn, admin)
      conn = post(conn, Routes.admin_user_path(conn, :create, user: @create_attrs))

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.admin_user_path(conn, :show, id)

      assert Repo.get!(User, id).email == @create_attrs.email
    end
  end

  describe "edit user" do
    test "renders form for editing chosen user", %{guest_conn: guest_conn, admin: admin} do
      conn = assign_user_to_session(guest_conn, admin)
      conn = get(conn, Routes.admin_user_path(conn, :edit, fixture(:user)))

      assert html_response(conn, 200) =~ "Imię i nazwisko"
      assert html_response(conn, 200) =~ "Henryk Testowny"
    end
  end

  describe "update user" do
    test "redirects when data is valid", %{guest_conn: guest_conn, admin: admin} do
      user = fixture(:user)

      conn = assign_user_to_session(guest_conn, admin)
      conn = put(conn, Routes.admin_user_path(conn, :update, user), user: @update_attrs)

      assert redirected_to(conn) == Routes.admin_user_path(conn, :show, user)
      assert Repo.get!(User, user.id).email == "test2@test.eu"
    end
  end

  describe "delete user" do
    test "deletes chosen user", %{guest_conn: guest_conn, admin: admin} do
      user = fixture(:user)

      conn = assign_user_to_session(guest_conn, admin)
      conn = delete(conn, Routes.admin_user_path(conn, :delete, user))

      assert redirected_to(conn) == Routes.admin_user_path(conn, :index)

      assert Repo.get(User, user.id) == nil
    end
 end
end
