defmodule Pjeski.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add :name, :string
      add :phone_code, :string
      add :phone, :string
      add :email, :string
      add :city, :string
      add :address, :string
      add :notes, :text

      timestamps()
    end

  end
end
