defmodule Pjeski.Repo.Migrations.SegregateDeerFilesPerTableId do
  use Ecto.Migration
  alias Pjeski.DeerRecords.DeerRecord
  import Ecto.Query, warn: false

  def up do
    if Mix.env != :test do
      uploaded_files_dir = File.cwd! <> "/uploaded_files"
      subscriptions_ids = File.ls!(uploaded_files_dir) |> Enum.map(&String.to_integer/1)

      for subscription_id <- subscriptions_ids do
        records_ids = (File.ls!(uploaded_files_dir <> "/#{subscription_id}")) |> Enum.map(&String.to_integer/1)
        record_ids_with_table_ids = Pjeski.Repo.all(from r in DeerRecord, where: r.id in ^records_ids and r.subscription_id == ^subscription_id, select: %{deer_table_id: r.deer_table_id, id: r.id})

        for %{deer_table_id: table_id, id: id} <- record_ids_with_table_ids do
          old_dir = uploaded_files_dir <> "/#{subscription_id}/#{id}"
          table_dir = uploaded_files_dir <> "/#{subscription_id}/#{table_id}"

          File.mkdir_p!(table_dir)
          new_dir = table_dir <> "/#{id}"

          IO.write "Moving '#{old_dir}' to #{new_dir}..."

          File.rename!(old_dir, new_dir)

          IO.puts " DONE"
        end
      end
    end
  end
end
