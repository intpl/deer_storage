defmodule PjeskiWeb.RegistrationController do
  use PjeskiWeb, :controller

  alias Pjeski.Users.UserSessionUtils
  alias Pjeski.Repo
  alias Pjeski.Users
  alias Pjeski.Users.User

  import PjeskiWeb.ControllerHelpers.ConfirmationHelpers, only: [send_confirmation_email: 2]

  def new(conn, _params), do: render(conn, "new.html", changeset: Pow.Plug.change_user(conn))
  def edit(conn, _params), do: render_edit_for_current_user(conn, Pow.Plug.change_user(conn))
  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.create_user(user_params)
    |> case do
      {:ok, user, conn} ->
        Users.upsert_subscription_link!(user.id, user.last_used_subscription_id, :raise, %{permission_to_manage_users: true})
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
      {:ok, %User{locale: locale}, conn} ->
        Gettext.put_locale(PjeskiWeb.Gettext, locale) # in case the user changed locale in this request

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

    user.available_subscriptions
    |> Enum.map(fn subscription -> subscription.id end)
    |> Enum.member?(requested_subscription_id)
    |> maybe_update_user_and_put_subscription_into_session(conn, user, requested_subscription_id)
    |> redirect(to: Routes.registration_path(conn, :edit))
  end

  # only admins can reset their subscriptions
  def reset_subscription_id(%{assigns: %{current_user: %{role: "admin"} = user}} = conn, _params) do
    maybe_update_user_and_put_subscription_into_session(true, conn, user, nil)
    |> redirect(to: Routes.registration_path(conn, :edit))
  end

  # let it fail if false is unmatched
  defp maybe_update_user_and_put_subscription_into_session(true, conn, user, requested_subscription_id) do
    Users.update_last_used_subscription_id!(user, requested_subscription_id)

    conn
    |> UserSessionUtils.put_into_session(:current_subscription_id, requested_subscription_id)
    |> put_flash(:info, gettext("Current subscription changed"))
  end

  defp render_edit_for_current_user(%{assigns: %{current_subscription: current_subscription}} = conn, changeset) do
    user = current_user_with_preloaded_subscriptions(conn)

    available_subscriptions = case current_subscription do
                                nil -> user.available_subscriptions
                                %{id: sub_id} -> Enum.reject(user.available_subscriptions, fn s -> s.id == sub_id end)
                              end

    render(conn, "edit.html",
      changeset: changeset,
      available_subscriptions: available_subscriptions,
      current_subscription: current_subscription |> maybe_preload_users
    )
  end

  defp current_user_with_preloaded_subscriptions(%{assigns: %{current_user: user}}) do
    user |> Repo.preload([:available_subscriptions, :last_used_subscription])
  end

  defp maybe_send_confirmation_email(%{assigns: %{current_user: %User{email: email, unconfirmed_email: email}}} = conn), do: conn
  defp maybe_send_confirmation_email(%{assigns: %{current_user: %User{email: _, unconfirmed_email: nil}}} = conn), do: conn
  defp maybe_send_confirmation_email(%{assigns: %{current_user: %User{email: _, unconfirmed_email: _} = user}} = conn) do
    send_confirmation_email(user, conn)

    conn
    |> put_flash(:info, gettext("Click the link in the confirmation email to change your email."))
  end

  defp maybe_preload_users(nil), do: nil
  defp maybe_preload_users(subscription), do: Repo.preload(subscription, :users)
end
