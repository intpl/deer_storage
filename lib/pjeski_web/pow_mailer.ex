defmodule PjeskiWeb.PowMailer do
  use Bamboo.Mailer, otp_app: :pjeski
  use Pow.Phoenix.Mailer

  import Bamboo.Email

  def cast(%{user: user, subject: subject, text: text, html: html}) do
    new_email(
      to: user.email,
      from: "no-reply@deerstorage.com",
      subject: subject,
      html_body: html,
      text_body: text
    )
  end

  def process(email) do
    deliver_now(email)
  end
end
