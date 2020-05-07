defmodule Pjeski.Repo.Migrations.AddDeerTablesToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :deer_tables, {:array, :map}, default: []
    end
  end
end
