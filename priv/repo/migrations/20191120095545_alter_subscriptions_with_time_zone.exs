defmodule Pjeski.Repo.Migrations.AlterSubscriptionsWithTimeZone do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :time_zone, :string, default: "Europe/Warsaw"
    end
  end
end
