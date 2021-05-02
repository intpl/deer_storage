defmodule DeerStorage.Repo.Migrations.CreateUserAvailableSubscriptionLinks do
  use Ecto.Migration

  def change do
    create table(:user_available_subscription_links) do
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)
      add(:subscription_id, references(:subscriptions, on_delete: :delete_all), primary_key: true)
      timestamps()
    end

    create(index(:user_available_subscription_links, [:subscription_id]))
    create(index(:user_available_subscription_links, [:user_id]))

    # TODO determine if this is needed in the future
    create(index(:user_available_subscription_links, [:user_id, :subscription_id]))

    create(
      unique_index(:user_available_subscription_links, [:user_id, :subscription_id], name: :user_id_available_subscription_id_unique_index)
    )
  end
end
