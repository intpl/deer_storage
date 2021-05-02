defmodule DeerStorageWeb.PowEmailConfirmation.MailerView do
  use DeerStorageWeb, :mailer_view

  def subject(:email_confirmation, _assigns), do: "Confirm your email address"
end
