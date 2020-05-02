defmodule Pjeski.Users.UserSessionUtils do
  alias Pow.Store.CredentialsCache
  alias Pjeski.Repo
  alias Pjeski.Subscriptions.Subscription
  alias Pjeski.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

  import Plug.Conn, only: [put_session: 3]

  @credentials_cache_config [backend: Application.get_env(:pjeski, :pow)[:cache_store_backend]]

  def get_token_from_conn(%{private: %{plug_session: %{"pjeski_auth" => token}}}), do: token
  def get_current_subscription_id_from_conn(%{private: %{plug_session: %{"current_subscription_id" => id}}}), do: id

  def user_sessions_keys(user) do
    CredentialsCache.sessions(@credentials_cache_config, user)
  end

  def delete_all_sessions_for_user(user) do
    for session_key <- user_sessions_keys(user) do
      CredentialsCache.delete(@credentials_cache_config, session_key)
    end

    {:ok}
  end

  def maybe_put_subscription_into_session(%{assigns: %{current_user: %{last_used_subscription_id: nil, role: "admin"}}} = conn) do
    conn |> put_session(:current_subscription_id, nil)
  end

  def maybe_put_subscription_into_session(%{assigns: %{current_user: %{last_used_subscription_id: nil} = user}} = conn) do
    conn |> put_session(:current_subscription_id, ensure_subscription_id_validity_for_user(user))
  end

  def maybe_put_subscription_into_session(%{assigns: %{current_user: %{last_used_subscription_id: subscription_id} = user}} = conn) do
    session_subscription_id = case Repo.get(Subscription, subscription_id) do
                             nil -> ensure_subscription_id_validity_for_user(user)
                             subscription ->
                               Repo.get_by!(UserAvailableSubscriptionLink, [user_id: user.id, subscription_id: subscription_id])

                               subscription.id
                           end

    conn |> put_session(:current_subscription_id, session_subscription_id)
  end

  defp ensure_subscription_id_validity_for_user(user) do
    new_subscription_id = users_first_available_subscription_id_or_nil(user)
    Pjeski.Users.update_last_used_subscription_id!(user, new_subscription_id)

    new_subscription_id
  end

  defp users_first_available_subscription_id_or_nil(user) do
    case List.last(user.available_subscriptions) do
      nil -> nil
      subscription -> subscription.id
    end
  end
end
