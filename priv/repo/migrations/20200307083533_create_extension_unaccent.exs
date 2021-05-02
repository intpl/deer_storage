defmodule DeerStorage.Repo.Migrations.CreateExtensionUnaccent do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION unaccent", "DROP EXTENSION unaccent"
  end
end
