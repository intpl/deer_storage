defmodule Pjeski.Repo.Migrations.AlterUsersWithLocales do
  use Ecto.Migration

  def change do
    LocaleEnum.create_type

    alter table(:users) do
      add :locale, LocaleEnum.type(), default: "en"
      add :expiry_date, :naive_datetime
    end
  end
end
