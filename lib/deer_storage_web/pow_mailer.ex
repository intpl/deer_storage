defmodule DeerStorageWeb.PowMailer do
  use Bamboo.Mailer, otp_app: :deer_storage
  use Pow.Phoenix.Mailer

  import Bamboo.Email

  def cast(%{user: user, subject: subject, text: text, html: html}) do
    new_email(
      to: user.email,
      from: "no-reply@mail.deerstorage.com",
      subject: subject,
      html_body: html,
      text_body: text
    )
  end

  def process(email) do
    deliver_later(email)
  end
end
