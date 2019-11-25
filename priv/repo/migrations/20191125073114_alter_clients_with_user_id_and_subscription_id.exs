defmodule Pjeski.Repo.Migrations.AlterClientsWithUserIdAndSubscriptionId do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      add :user_id, references(:users), on_delete: :nothing
      add :subscription_id, references(:subscriptions), on_delete: :nothing
    end

    create index(:clients, [:subscription_id])
    create index(:clients, [:subscription_id, :user_id])
  end
end
