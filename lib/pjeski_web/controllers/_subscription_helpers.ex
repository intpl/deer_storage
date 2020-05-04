defmodule PjeskiWeb.ControllerHelpers.SubscriptionHelpers do
  use PjeskiWeb, :controller

  def verify_if_subscription_is_expired(%{assigns: %{current_subscription: subscription}} = conn, _opts) do
    case Date.compare(Date.utc_today, subscription.expires_on) == :lt do
      true -> conn
      false ->
        conn
        |> put_flash(:error, gettext("Your subscription expired"))
        |> redirect(to: Routes.registration_path(conn, :edit))
    end
  end
end
