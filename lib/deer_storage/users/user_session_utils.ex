defmodule DeerStorage.Users.UserSessionUtils do
  alias Pow.Store.CredentialsCache
  alias DeerStorage.Repo
  alias DeerStorage.Subscriptions.Subscription
  alias DeerStorage.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink

  @credentials_cache_config [
    backend: Application.get_env(:deer_storage, :pow)[:cache_store_backend]
  ]

  def get_live_user(socket, %{"deer_storage_auth" => signed_token}) do
    conn = struct!(Plug.Conn, secret_key_base: socket.endpoint.config(:secret_key_base))
    salt = Atom.to_string(Pow.Plug.Session)

    with {:ok, token} <- Pow.Plug.verify_token(conn, salt, signed_token, otp_app: :deer_storage),
         {user, _metadata} <- CredentialsCache.get(@credentials_cache_config, token) do
      user
    else
      _any -> nil
    end
  end

  def get_token_from_conn(%{private: %{plug_session: %{"deer_storage_auth" => token}}}), do: token
  # TODO: remove this lol
  def put_into_session(conn, key, value), do: Plug.Conn.put_session(conn, key, value)

  def assign_current_user_and_preload_available_subscriptions(conn, user) do
    Pow.Plug.assign_current_user(
      conn,
      user |> Repo.preload(:available_subscriptions),
      Pow.Plug.fetch_config(conn)
    )
  end

  def user_sessions_keys(user) do
    CredentialsCache.sessions(@credentials_cache_config, user)
  end

  def delete_all_sessions_for_user!(user) do
    for session_key <- user_sessions_keys(user) do
      CredentialsCache.delete(@credentials_cache_config, session_key)
    end
  end

  def maybe_put_subscription_into_session(
        %{assigns: %{current_user: %{last_used_subscription_id: nil, role: "admin"}}} = conn
      ) do
    conn |> put_into_session(:current_subscription_id, nil)
  end

  def maybe_put_subscription_into_session(
        %{assigns: %{current_user: %{last_used_subscription_id: nil} = user}} = conn
      ) do
    conn
    |> put_into_session(:current_subscription_id, ensure_subscription_id_validity_for_user(user))
  end

  def maybe_put_subscription_into_session(
        %{assigns: %{current_user: %{last_used_subscription_id: subscription_id} = user}} = conn
      ) do
    session_subscription_id =
      case Repo.get(Subscription, subscription_id) do
        nil ->
          ensure_subscription_id_validity_for_user(user)

        subscription ->
          Repo.get_by!(UserAvailableSubscriptionLink,
            user_id: user.id,
            subscription_id: subscription_id
          )

          subscription.id
      end

    conn |> put_into_session(:current_subscription_id, session_subscription_id)
  end

  defp ensure_subscription_id_validity_for_user(user) do
    new_subscription_id = users_last_available_subscription_id_or_nil(user)
    DeerStorage.Users.update_last_used_subscription_id!(user, new_subscription_id)

    new_subscription_id
  end

  defp users_last_available_subscription_id_or_nil(user) do
    case List.last(user.available_subscriptions) do
      nil -> nil
      subscription -> subscription.id
    end
  end
end
