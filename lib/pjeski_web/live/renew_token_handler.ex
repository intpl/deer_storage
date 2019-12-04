defmodule PjeskiWeb.LiveHelpers.RenewTokenHandler do
  defmacro __using__([]) do
    quote do
      import Pjeski.Users.UserSessionUtils, only: [renew_token: 2]

      def handle_info(:renew_token, %{assigns: %{token: token}, id: socket_id} = socket) do
        incremented = (socket.assigns[:renew_token_count] || 0) + 1
        renew_token(token, "#{socket_id}_renew_#{incremented}")

        {:noreply, socket |> assign(renew_token_count: incremented)}
      end
    end
  end
end
