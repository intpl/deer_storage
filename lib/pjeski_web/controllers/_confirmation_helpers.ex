defmodule PjeskiWeb.ControllerHelpers.ConfirmationHelpers do
  alias PjeskiWeb.Router.Helpers, as: Routes
  alias PowEmailConfirmation.Phoenix.Mailer

  def send_confirmation_email(user, conn) do
    url               = confirmation_url(conn, user.email_confirmation_token)
    unconfirmed_user  = %{user | email: user.unconfirmed_email || user.email}
    email             = Mailer.email_confirmation(conn, unconfirmed_user, url)

    Pow.Phoenix.Mailer.deliver(conn, email)
  end

  defp confirmation_url(conn, token) do
    Routes.confirmation_path(conn, :show, token)
  end
end
