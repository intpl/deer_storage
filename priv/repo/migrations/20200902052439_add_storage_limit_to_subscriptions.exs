defmodule DeerStorage.Repo.Migrations.AddStorageLimitToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :storage_limit_kilobytes, :integer, default: 0
    end
  end
end
