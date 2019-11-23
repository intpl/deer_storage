defmodule PjeskiWeb.AuthErrorHandler do
  use PjeskiWeb, :controller
  alias Plug.Conn

  @spec call(Conn.t(), atom()) :: Conn.t()
  def call(conn, :not_authenticated) do
    conn
    |> put_flash(:error, gettext( "You've to be authenticated first"))
    |> redirect(to: Routes.session_path(conn, :new))
  end

  @spec call(Conn.t(), atom()) :: Conn.t()
  def call(conn, :already_authenticated) do
    conn
    |> put_flash(:error, gettext( "You're already authenticated"))
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
