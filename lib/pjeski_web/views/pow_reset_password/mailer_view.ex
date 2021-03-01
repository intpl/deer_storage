defmodule PjeskiWeb.PowResetPassword.MailerView do
  use PjeskiWeb, :mailer_view

  def subject(:reset_password, _assigns), do: "Reset password link"
end
