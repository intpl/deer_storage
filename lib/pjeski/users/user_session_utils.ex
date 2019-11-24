defmodule Pjeski.Users.UserSessionUtils do
  alias Pjeski.Subscriptions

  @credentials_cache_config [backend: Application.get_env(:pjeski, :pow)[:cache_store_backend]]

  def user_sessions_keys(user) do
    Pow.Store.CredentialsCache.sessions(@credentials_cache_config, user)
  end

  def delete_all_sessions_for_user(user) do
    for session_key <- user_sessions_keys(user) do
      Pow.Store.CredentialsCache.delete(@credentials_cache_config, session_key)
    end

    {:ok}
  end

  def delete_all_sessions_for_expired_subscriptions_users do
    users = Subscriptions.list_expired_subscriptions
            |> Enum.map(&(&1.users))
            |> List.flatten

    for user <- users, do: delete_all_sessions_for_user(user)
  end
end
