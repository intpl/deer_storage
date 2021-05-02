defmodule DeerStorage.Repo.Migrations.AddDeerFileLimitToSubscription do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :deer_files_limit, :integer, default: 0
    end
  end
end
