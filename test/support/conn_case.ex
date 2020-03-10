defmodule PjeskiWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      alias PjeskiWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint PjeskiWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Pjeski.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Pjeski.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  setup %{conn: conn} do
    user = %Pjeski.Users.User{email: "test@example.com", name: "Test User", id: 1, role: "admin", locale: "en"}
    admin_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, admin_conn: admin_conn}
  end

end
