defmodule Pjeski.Test.SessionHelpers do
  import Pjeski.Users.UserSessionUtils, only: [maybe_put_subscription_into_session: 1]

  def assign_user_to_session(conn, user) do
      conn |> Plug.Test.init_test_session(%{}) |> Pow.Plug.assign_current_user(user, []) |> maybe_put_subscription_into_session
  end
end
