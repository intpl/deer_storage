defmodule Pjeski.Repo.Migrations.CreateTableAnimals do
  use Ecto.Migration

  def change do
    create table(:animals) do
      add :name, :string
      add :birth_year, :date
      add :notes, :text
      add :client_id, references(:clients), on_delete: :nothing
      add :animal_kind_id, references(:animal_kinds), on_delete: :nothing
      add :animal_breed_id, references(:animal_breeds), on_delete: :nothing
      add :subscription_id, references(:subscriptions), on_delete: :nothing
      add :user_id, references(:users), on_delete: :nothing
      add :last_changed_by_user_id, references(:users), on_delete: :nothing

      timestamps()
    end

    create index(:animals, [:subscription_id])
    create index(:animals, [:subscription_id, :user_id])
  end
end
