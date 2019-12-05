defmodule Pjeski.Repo.Migrations.CreateTableAnimalKinds do
  use Ecto.Migration

  def change do
    create table(:animal_kinds) do
      add :name, :string
      add :notes, :text
      add :subscription_id, references(:subscriptions), on_delete: :nothing
      add :last_changed_by_user_id, references(:users), on_delete: :nothing

      timestamps()
    end

    create index(:animal_kinds, [:subscription_id])
  end
end
