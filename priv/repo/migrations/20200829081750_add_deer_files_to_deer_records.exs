defmodule Pjeski.Repo.Migrations.AddDeerFilesToDeerRecords do
  use Ecto.Migration

  def change do
    alter table(:deer_records) do
      add :deer_files, {:array, :map}, default: []
    end
  end
end
