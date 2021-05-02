defmodule DeerStorage.Repo.Migrations.AddEditingBoolToDeerSharedRecords do
  use Ecto.Migration

  def change do
    alter table(:shared_records) do
      add :is_editable, :boolean, default: false
    end
  end
end
