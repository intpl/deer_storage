defmodule Pjeski.Repo.Migrations.AddDeerRecordsPerTableLimitToSubscription do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :deer_records_per_table_limit, :integer, default: 0
    end
  end
end
