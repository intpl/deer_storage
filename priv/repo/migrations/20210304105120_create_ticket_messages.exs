defmodule Pjeski.Repo.Migrations.CreateTicketMessages do
  use Ecto.Migration

  def change do
    create table(:ticket_messages) do
      add :body, :text
      add :ticket_id, references(:tickets, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:ticket_messages, [:ticket_id])
  end
end
