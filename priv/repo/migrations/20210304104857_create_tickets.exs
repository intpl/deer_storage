defmodule Pjeski.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :title, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :is_opened, :boolean

      timestamps()
    end

    create index(:tickets, [:user_id])
  end
end
