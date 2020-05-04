defmodule PjeskiWeb.GetCurrentSubscriptionPlug do
  import Plug.Conn, only: [assign: 3]

  alias Pjeski.{Subscriptions.Subscription, Repo}

  def init(_opts), do: nil

  def call(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts), do: conn
  def call(%{private: %{plug_session: %{"current_subscription_id" => nil}}} = conn, _opts), do: assign(conn, :current_subscription, nil)
  def call(%{private: %{plug_session: %{"current_subscription_id" => id}}} = conn, _opts) do
    assign(conn, :current_subscription, Repo.get(Subscription, id))
  end
end
