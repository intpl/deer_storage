defmodule Pjeski.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :expires_on, :date, null: false
      add :data, :jsonb

      timestamps()
    end

    alter table(:users) do
      add :subscription_id, references(:subscriptions, on_delete: :nilify_all)
    end

    create index(:users, [:subscription_id])
    create unique_index(:subscriptions, [:email])
  end
end
