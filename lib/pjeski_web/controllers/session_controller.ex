defmodule PjeskiWeb.SessionController do
  use PjeskiWeb, :controller

  alias Pjeski.Users.User
  alias Pjeski.Subscriptions

  def new(conn, _params) do
    changeset = Pow.Plug.change_user(conn)

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.authenticate_user(user_params)
    |> verify_subscription_valid?()
  end

  def delete(conn, _params) do
    {:ok, conn} = Pow.Plug.clear_authenticated_user(conn)

    redirect(conn, to: Routes.page_path(conn, :index))
  end

  defp verify_subscription_valid?({:ok, conn}) do
    conn
    |> Pow.Plug.current_user()
    |> subscription_valid?
    |> case do
         {true, user_role} ->
           redirect(conn, to: dashboard_path_for(user_role))
         _ ->
           {:ok, conn} = Pow.Plug.clear_authenticated_user(conn)

           conn
           |> put_flash(:error, gettext("Your subscription is inactive."))
           |> redirect(to: Routes.session_path(conn, :new))
       end
  end

  defp verify_subscription_valid?({:error, conn}) do
    changeset = Pow.Plug.change_user(conn, conn.params["user"])

    conn
    |> put_flash(:error, gettext("Invalid e-mail or password"))
    |> render("new.html", changeset: changeset)
  end

  defp subscription_valid?(%User{role: "admin"}), do: { true, :admin }
  defp subscription_valid?(%User{subscription_id: nil}), do: { false, :user }
  defp subscription_valid?(%User{subscription_id: subscription_id}) when is_number(subscription_id) do
    subscription = Subscriptions.get_subscription!(subscription_id) # FIXME add time zone support

    {
      Date.compare(Date.utc_today, subscription.expires_on) == :lt,
      :user
    }
  end
end
