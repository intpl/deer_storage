defmodule Pjeski.Repo.Migrations.AlterUsersWithClinicName do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :displayed_name, :string
    end
  end
end
