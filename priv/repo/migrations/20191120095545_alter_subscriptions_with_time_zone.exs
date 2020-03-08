defmodule Pjeski.Repo.Migrations.AlterUsersWithTimeZone do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :time_zone, :string, default: "Europe/Warsaw"
    end
  end
end
