defmodule Pjeski.Repo.Migrations.CreateTableAnimalBreeds do
  use Ecto.Migration

  def change do
    create table(:animal_breeds) do
      add :name, :string
      add :notes, :text
      add :animal_kind_id, references(:animal_kinds), on_delete: :nothing
      add :subscription_id, references(:subscriptions), on_delete: :nothing
      add :last_changed_by_user_id, references(:users), on_delete: :nothing

      timestamps()
    end

    create index(:animal_breeds, [:subscription_id])
  end
end
