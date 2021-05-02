defmodule DeerStorage.Repo.Migrations.AddPermissionToManageUsersToUserAvailableSubscriptionLinks do
  use Ecto.Migration

  def change do
    alter table(:user_available_subscription_links) do
      add :permission_to_manage_users, :boolean, default: false
    end
  end
end
