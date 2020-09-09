defmodule Pjeski.Repo.Migrations.AddDeerColumnsPerTableLimitToSubscription do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :deer_columns_per_table_limit, :integer, default: 0
    end
  end
end
