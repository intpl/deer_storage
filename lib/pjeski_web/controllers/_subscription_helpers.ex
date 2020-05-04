defmodule PjeskiWeb.ControllerHelpers.SubscriptionHelpers do
  use PjeskiWeb, :controller

  def verify_if_subscription_is_expired(%{assigns: %{current_subscription_is_expired: false}} = conn, _opts), do: conn
  def verify_if_subscription_is_expired(%{assigns: %{current_subscription_is_expired: true}} = conn, _opts) do
    conn
    |> put_flash(:error, gettext("Your subscription expired"))
    |> redirect(to: Routes.registration_path(conn, :edit))
  end
end
