defmodule DeerStorageWeb.PageController do
  use DeerStorageWeb, :controller

  import DeerStorageWeb.ControllerHelpers.UserHelpers, only: [redirect_to_dashboard: 2]

  def index(conn, _params) do
    render(conn, "index.html")
  rescue
    Phoenix.Template.UndefinedError ->
      redirect_to_dashboard_or_new_session(conn)
  end

  defp redirect_to_dashboard_or_new_session(conn) do
    case Pow.Plug.current_user(conn) do
      %{last_used_subscription_id: id} ->
        redirect_to_dashboard(conn, id)

      _ ->
        redirect(conn, to: Routes.session_path(conn, :new))
    end
  end
end
