defmodule PjeskiWeb.PowEmailConfirmation.MailerView do
  use PjeskiWeb, :mailer_view

  def subject(:email_confirmation, _assigns), do: "Confirm your email address"
end
