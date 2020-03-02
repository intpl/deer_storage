defmodule Pjeski.Repo.Migrations.AlterUsersWithLocales do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :locale, :string, default: "en", null: false
      add :expiry_date, :naive_datetime
    end
  end
end
