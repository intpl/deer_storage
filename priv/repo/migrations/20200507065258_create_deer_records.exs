defmodule Pjeski.Repo.Migrations.CreateDeerRecords do
  use Ecto.Migration

  def change do
    create table(:deer_records) do
      add :subscription_id, references(:subscriptions, on_delete: :delete_all), null: false
      add :created_by_user_id, references(:users, on_delete: :nilify_all)
      add :updated_by_user_id, references(:users, on_delete: :nilify_all)
      add :deer_table_id, :string, null: false
      add :deer_fields, {:array, :map}, default: []

      timestamps()
    end

    create index(:deer_records, [:subscription_id])
    create index(:deer_records, [:subscription_id, :deer_table_id])
  end
end
