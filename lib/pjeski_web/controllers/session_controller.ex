defmodule PjeskiWeb.SessionController do
  use PjeskiWeb, :controller

  import PjeskiWeb.ConfirmationHelpers, only: [send_confirmation_email: 2]

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
    conn
    |> Pow.Plug.delete
    |> redirect(to: Routes.page_path(conn, :index))
  end

  defp verify_subscription_valid?({:ok, conn}) do
    user = conn |> Pow.Plug.current_user()

    user
    |> subscription_valid?
    |> case do
         {true, user_role} ->
           pow_config = Pow.Plug.fetch_config(conn)

           case email_confirmed?(user) do
             true ->
               Pow.Plug.assign_current_user(conn, Pjeski.Repo.preload(user, :subscription), pow_config)
               conn |> redirect(to: dashboard_path_for(user_role))
             false ->
               send_confirmation_email(user, conn)

               conn
               |> Pow.Plug.delete
               |> put_flash(:info, gettext("E-mail not confirmed. Confirmation e-mail has been sent again"))
               |> redirect(to: Routes.session_path(conn, :new))
           end

         _ ->
           conn
           |> Pow.Plug.delete
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

  defp email_confirmed?(%{email_confirmed_at: nil, email_confirmation_token: token, unconfirmed_email: nil}) when not is_nil(token), do: false
  defp email_confirmed?(_user), do: true
end
