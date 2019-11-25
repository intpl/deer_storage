defmodule Pjeski.Users.UserSessionUtils do
  alias Pjeski.Subscriptions
  alias Pow.Store.CredentialsCache

  @credentials_cache_config [backend: Application.get_env(:pjeski, :pow)[:cache_store_backend]]

  def user_from_live_session(%{"pjeski_auth" => token}) do
    # returns :not_found if no user session, but let's keep it failing/unmatched for security reasons
    {user, _} = CredentialsCache.get(@credentials_cache_config, token)

    user
  end

  def user_sessions_keys(user) do
    CredentialsCache.sessions(@credentials_cache_config, user)
  end

  def delete_all_sessions_for_user(user) do
    for session_key <- user_sessions_keys(user) do
      CredentialsCache.delete(@credentials_cache_config, session_key)
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
