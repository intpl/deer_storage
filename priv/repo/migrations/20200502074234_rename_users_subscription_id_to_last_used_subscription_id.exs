defmodule Pjeski.Repo.Migrations.RenameUsersSubscriptionIdToLastUsedSubscriptionId do
  use Ecto.Migration

  def change do
    rename table("users"), :subscription_id, to: :last_used_subscription_id
  end
end
