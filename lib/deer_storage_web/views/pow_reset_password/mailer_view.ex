defmodule DeerStorageWeb.PowResetPassword.MailerView do
  use DeerStorageWeb, :mailer_view

  def subject(:reset_password, _assigns), do: "Reset password link"
end
