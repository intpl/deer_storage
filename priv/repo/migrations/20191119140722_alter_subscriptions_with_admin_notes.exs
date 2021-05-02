defmodule DeerStorage.Repo.Migrations.AlterSubscriptionsWithAdminNotes do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :admin_notes, :text
    end
  end
end
