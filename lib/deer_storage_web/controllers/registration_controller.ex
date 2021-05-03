defmodule DeerStorageWeb.RegistrationController do
  import DeerStorage.FeatureFlags, only: [registration_enabled?: 0, promote_first_user_to_admin_enabled?: 0, mailing_enabled?: 0]

  use DeerStorageWeb, :controller

  alias DeerStorage.Users.UserSessionUtils
  alias DeerStorage.Repo
  alias DeerStorage.Users
  alias DeerStorage.Users.User

  import Plug.Conn, only: [put_session: 3, get_session: 2]
  import DeerStorageWeb.ControllerHelpers.ConfirmationHelpers, only: [send_confirmation_email: 2]
  import DeerStorageWeb.ControllerHelpers.FeatureFlagsHelpers

  def new(conn, _params) do
    wrap_feature_endpoint(registration_enabled?(), conn, fn ->
      render_new_with_captcha(conn, Pow.Plug.change_user(conn))
    end)
  end

  def edit(conn, _params), do: render_edit_for_current_user(conn, Pow.Plug.change_user(conn))

  def create(conn, %{"user" => user_params}) do
    wrap_feature_endpoint(registration_enabled?(), conn, fn ->
      {user_captcha_string, user_params} = Map.pop!(user_params, "captcha")

      if captcha_solved_correctly?(conn, user_captcha_string) do
        conn
        |> Pow.Plug.create_user(user_params)
        |> case do
             {:ok, user, conn} ->
               conn
               |> do_register_user!(user)
               |> maybe_send_confirmation_email
               |> delete_plug_session_and_redirect
             {:error, changeset, conn} -> render_new_with_captcha(conn, changeset)
           end
      else
        user_changeset = User.changeset(%User{}, user_params)

        conn
        |> put_flash(:error, gettext("Invalid answer to math question"))
        |> render_new_with_captcha(user_changeset)
      end
    end)
  end

  def update(conn, %{"user" => user_params}) do
    case mailing_enabled?() do
      true -> do_update_user!(conn, user_params)
      false ->
        case [user_params["email"], Pow.Plug.current_user(conn).email] do
          [email, email] -> do_update_user!(conn, user_params)
          [_, _] ->
            changeset = User.changeset(%User{}, user_params)

            conn
            |> put_flash(:error, gettext("You cannot change your e-mail. Ask your administrator to do it for you."))
            |> render_edit_for_current_user(changeset)
        end
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

  defp do_register_user!(conn, user) do
    Users.upsert_subscription_link!(user.id, user.last_used_subscription_id, :raise, %{permission_to_manage_users: true})
    Users.notify_subscribers!([:user, :created], user)

    conn
  end

  defp do_update_user!(conn, user_params) do
    conn |> Pow.Plug.update_user(user_params) |> case do
      {:ok, %User{locale: locale}, conn} ->
        Gettext.put_locale(DeerStorageWeb.Gettext, locale) # in case the user changed locale in this request

        conn
        |> maybe_send_confirmation_email_on_update
        |> put_flash(:info, gettext("Account updated"))
        |> render_edit_for_current_user(Pow.Plug.change_user(conn))

      {:error, changeset, conn} ->
        render_edit_for_current_user(conn, changeset)
    end
  end

  # let it fail if false is unmatched
  defp maybe_update_user_and_put_subscription_into_session(true, conn, user, requested_subscription_id) do
    Users.update_last_used_subscription_id!(user, requested_subscription_id)

    conn
    |> UserSessionUtils.put_into_session(:current_subscription_id, requested_subscription_id)
    |> put_flash(:info, gettext("Current database changed"))
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

  defp captcha_solved_correctly?(conn, user_solution) do
    captcha_solution = get_session(conn, "captcha_solution")

    case Integer.parse(user_solution) do
      {^captcha_solution, ""} -> true
      _ -> false
    end
  end

  defp render_new_with_captcha(conn, changeset) do
    {solution, challenge_text} = random_captcha()

    conn
    |> put_session(:captcha_solution, solution)
    |> render("new.html", changeset: changeset, captcha_challenge: challenge_text)
  end

  defp random_captcha do
    num1 = Enum.random(0..20)
    num2 = Enum.random(0..50)

    {
      Enum.sum([num1, num2]),
      gettext("Please add %{num1} to %{num2}:", num1: num1, num2: num2)
    }
  end

  defp current_user_with_preloaded_subscriptions(%{assigns: %{current_user: user}}) do
    user |> Repo.preload([:available_subscriptions, :last_used_subscription])
  end

  defp maybe_send_confirmation_email_on_update(%{assigns: %{current_user: %User{email: email, unconfirmed_email: email}}} = conn), do: conn
  defp maybe_send_confirmation_email_on_update(%{assigns: %{current_user: %User{email: _, unconfirmed_email: nil}}} = conn), do: conn
  defp maybe_send_confirmation_email_on_update(%{assigns: %{current_user: user}} = conn) do
    case mailing_enabled?() do
      true ->
        send_confirmation_email(user, conn)

        put_flash(conn, :info, gettext("Click the link in the confirmation email to change your email."))
      false -> put_flash(conn, :info, gettext("E-mailing is disabled."))
    end
  end

  defp maybe_send_confirmation_email(%{assigns: %{current_user: user}} = conn) do
    case [mailing_enabled?(), promote_first_user_to_admin_enabled?(), user] do
      [_mailing_flag, true = _autopromote_enabled, %{id: 1}] ->
        # TODO fix deprecation warning
        {:ok, user, conn} = PowEmailConfirmation.Plug.confirm_email(conn, user.email_confirmation_token)
        {:ok, user} = Users.toggle_admin!(user)

        conn
        |> Pow.Plug.assign_current_user(user, Pow.Plug.fetch_config(conn))
        |> put_flash(:info, gettext("You now can log in to your account"))
      [true = _mailing_enabled, _autopromote_flag, _user] ->
        send_confirmation_email(user, conn)

        put_flash(conn, :info, gettext("Click the link in the confirmation email to activate your account."))
      [false = _mailing_disabled, _autopromote_flag, _user] ->
        put_flash(conn, :info, gettext("E-mailing is disabled. You must be confirmed by an administrator"))
    end
  end

  defp delete_plug_session_and_redirect(conn) do
    conn
    |> Pow.Plug.delete
    |> redirect(to: Routes.session_path(conn, :new))
  end

  defp maybe_preload_users(nil), do: nil
  defp maybe_preload_users(subscription), do: Repo.preload(subscription, :users)
end
