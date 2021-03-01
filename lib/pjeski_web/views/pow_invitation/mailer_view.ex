defmodule PjeskiWeb.PowInvitation.MailerView do
  use PjeskiWeb, :mailer_view

  def subject(:invitation, _assigns), do: "You've been invited"
end
