defmodule Pjeski.Repo.Migrations.RemoveExpiryDateFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :expiry_date
    end
  end
end
