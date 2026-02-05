defmodule DeerStorageWeb.GetCurrentSubscriptionPlug do
  import Plug.Conn, only: [assign: 3]

  alias DeerStorage.{Subscriptions.Subscription, Repo}

  def init(_opts), do: nil

  def call(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts), do: conn

  def call(%{private: %{phoenix_live_view: {_, live_view_opts}}} = conn, _opts) do
    case Keyword.fetch(live_view_opts, :layout) do
      {:ok, {_, "without_navigation.html"}} -> conn
      _ -> conn |> assign_subscription
    end
  end

  def call(conn, _opts), do: assign_subscription(conn)

  defp assign_subscription(
         %{private: %{plug_session: %{"current_subscription_id" => nil}}} = conn
       ),
       do: assign(conn, :current_subscription, nil)

  defp assign_subscription(%{private: %{plug_session: %{"current_subscription_id" => id}}} = conn) do
    subscription = Repo.get(Subscription, id)
    is_expired = Date.diff(subscription.expires_on, Date.utc_today()) < 1

    conn
    |> assign(:current_subscription, subscription)
    |> assign(:current_subscription_is_expired, is_expired)
  end
end
