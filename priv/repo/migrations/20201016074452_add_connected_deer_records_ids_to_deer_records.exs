defmodule Pjeski.Repo.Migrations.AddConnectedDeerRecordsIdsToDeerRecords do
  use Ecto.Migration

  def change do
    alter table(:deer_records) do
      add :connected_deer_records_ids, {:array, :bigint}, default: []
    end
  end
end
