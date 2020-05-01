defmodule PjeskiWeb.RegistrationController do
  use PjeskiWeb, :controller

  alias Pjeski.Repo
  alias Pjeski.Users
  alias Pjeski.Users.User

  import PjeskiWeb.ConfirmationHelpers, only: [send_confirmation_email: 2]

  def new(conn, _params) do
    render(conn, "new.html", changeset: Pow.Plug.change_user(conn))
  end

  def edit(conn, _params) do
    render_edit_for_current_user(conn, Pow.Plug.change_user(conn))
  end

  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.create_user(user_params)
    |> case do
      {:ok, user, conn} ->
        Users.upsert_subscription_link!(user.id, user.subscription_id, :raise)
        Users.notify_subscribers!([:user, :created], user)
        send_confirmation_email(user, conn)

        conn
        |> Pow.Plug.delete
        |> put_flash(:info, gettext("Please confirm your e-mail before logging in"))
        |> redirect(to: Routes.session_path(conn, :new))
      {:error, changeset, conn} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def update(conn, %{"user" => user_params}) do
    conn |> Pow.Plug.update_user(user_params) |> case do
      {:ok, _user, conn} ->
        conn
        |> maybe_send_confirmation_email
        |> put_flash(:info, gettext("Account updated"))
        |> render_edit_for_current_user(Pow.Plug.change_user(conn))

      {:error, changeset, conn} ->
        render_edit_for_current_user(conn, changeset)
    end
  end

  def switch_subscription_id(conn, %{"subscription_id" => requested_subscription_id}) do
    user = current_user_with_preloaded_subscriptions(conn)
    requested_subscription_id = requested_subscription_id |> String.to_integer

    is_subscription_id_valid? = user.available_subscriptions
    |> Enum.map(fn subscription -> subscription.id end)
    |> Enum.member?(requested_subscription_id)

    case is_subscription_id_valid? do
      true ->
        Users.update_subscription_id!(user, requested_subscription_id)

        conn
        |> Pow.Plug.delete
        |> put_flash(:info, gettext("Successfully changed subscription. Please log back in."))
        |> redirect(to: Routes.registration_path(conn, :edit))
      false ->
        conn
        |> put_flash(:error, "Illegal action. Reported") # TODO
        |> redirect(to: Routes.registration_path(conn, :edit))
    end
  end

  defp render_edit_for_current_user(conn, changeset) do
    user = current_user_with_preloaded_subscriptions(conn)
    available_subscriptions = Enum.reject(
      user.available_subscriptions, fn s -> s.id == user.subscription_id end
    )

    render(conn, "edit.html",
      changeset: changeset,
      navigation_template_always: "navigation_outside_app.html",
      available_subscriptions: available_subscriptions,
      current_subscription: user.subscription
    )
  end

  defp current_user_with_preloaded_subscriptions(%{assigns: %{current_user: user}}) do
    user |> Repo.preload([:available_subscriptions, :subscription])
  end

  defp maybe_send_confirmation_email(%{assigns: %{current_user: %User{email: email, unconfirmed_email: email}}} = conn), do: conn
  defp maybe_send_confirmation_email(%{assigns: %{current_user: %User{email: _, unconfirmed_email: nil}}} = conn), do: conn
  defp maybe_send_confirmation_email(%{assigns: %{current_user: %User{email: _, unconfirmed_email: _} = user}} = conn) do
    send_confirmation_email(user, conn)

    conn
    |> put_flash(:info, gettext("Click the link in the confirmation email to change your email."))
  end
end
