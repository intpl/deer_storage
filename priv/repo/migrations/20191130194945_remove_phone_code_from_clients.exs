defmodule Pjeski.Repo.Migrations.RemovePhoneCodeFromClients do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      remove :phone_code
    end
  end
end
