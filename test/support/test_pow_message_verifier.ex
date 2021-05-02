defmodule DeerStorage.Test.Pow.MessageVerifier do
  def sign(_conn, salt, message, _config),
    do: "signed.#{salt}.#{message}"

  def verify(_conn, salt, message, _config) do
    prepend = "signed." <> salt <> "."

    case String.replace(message, prepend, "") do
      ^message -> :error
      message  -> {:ok, message}
    end
  end
end
