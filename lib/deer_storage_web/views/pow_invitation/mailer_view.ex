defmodule DeerStorageWeb.PowInvitation.MailerView do
  use DeerStorageWeb, :mailer_view

  def subject(:invitation, _assigns), do: "You've been invited"
end
