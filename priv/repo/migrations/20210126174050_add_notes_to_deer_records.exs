defmodule DeerStorage.Repo.Migrations.AddNotesToDeerRecords do
  use Ecto.Migration

  def change do
    alter table(:deer_records) do
      add :notes, :text
    end
  end
end
