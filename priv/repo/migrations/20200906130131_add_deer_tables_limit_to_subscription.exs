defmodule DeerStorage.Repo.Migrations.AddDeerTablesLimitToSubscription do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :deer_tables_limit, :integer, default: 0
    end
  end
end
