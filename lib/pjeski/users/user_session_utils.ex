defmodule Pjeski.Users.UserSessionUtils do
  alias Pow.Store.CredentialsCache

  @credentials_cache_config [backend: Application.get_env(:pjeski, :pow)[:cache_store_backend]]

  def renew_token(token, fingerprint) do
    :ok = CredentialsCache.put(
      @credentials_cache_config,
      token,
      {
        user_from_auth_token(token),
        inserted_at: :os.system_time(:millisecond),
        fingerprint: fingerprint
      }
    )
  end

  def user_from_auth_token(token) do
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
end
