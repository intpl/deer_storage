defmodule Pjeski.Repo.Migrations.CreateSharedFiles do
  use Ecto.Migration

  def change do
    create table(:shared_files, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :deer_record_id, references("deer_records", on_delete: :delete_all)
      add :expires_on, :utc_datetime, null: false
      add :created_by_user_id, references("users", on_delete: :nothing)
      add :subscription_id, references("subscriptions", on_delete: :delete_all)
      add :deer_file_id, :string

      timestamps(updated_at: false)
    end
  end
end
