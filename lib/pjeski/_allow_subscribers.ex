defmodule Pjeski.AllowSubscribers do
  defmacro __using__(module) do
    quote do
      def subscribe, do: :ok = Phoenix.PubSub.subscribe(Pjeski.PubSub, unquote(inspect(module)))

      def notify_subscribers({:ok, result}, event) do
        Phoenix.PubSub.broadcast!(Pjeski.PubSub, unquote(inspect(module)), {unquote(module), event, result})

        {:ok, result}
      end
    end
  end
end
