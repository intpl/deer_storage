defmodule DeerStorage.Repo.Migrations.RenameDisplayedNameToNameInUsers do
  use Ecto.Migration

  def change do
    rename table(:users), :displayed_name, to: :name
  end
end
