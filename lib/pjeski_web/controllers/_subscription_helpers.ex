defmodule PjeskiWeb.ControllerHelpers.SubscriptionHelpers do
  use PjeskiWeb, :controller
  import Pjeski.Users.UserSessionUtils, only: [get_current_subscription_id_from_conn: 1]

  alias Pjeski.Subscriptions

  def verify_if_subscription_is_expired(conn, _opts) do
    subscription = get_current_subscription_id_from_conn(conn) |> Subscriptions.get_subscription!

    case Date.compare(Date.utc_today, subscription.expires_on) == :lt do
      true -> conn
      false ->
        conn
        |> put_flash(:error, gettext("Your subscription expired"))
        |> redirect(to: Routes.registration_path(conn, :edit))
    end
  end
end
