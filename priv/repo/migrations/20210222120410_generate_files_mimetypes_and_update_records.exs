defmodule Pjeski.Repo.Migrations.GenerateFilesMimetypesAndUpdateRecords do
  use Ecto.Migration
  import Ecto.Query, warn: false
  import Ecto.Changeset

  def change do
    records_with_files = Pjeski.DeerRecords.DeerRecord |> where([r], fragment("cardinality(?) > 0", field(r, :deer_files))) |> Pjeski.Repo.all

    for %{deer_files: deer_files, deer_table_id: deer_table_id, subscription_id: subscription_id, id: record_id} = record <- records_with_files do
      new_deer_files = Enum.map(deer_files, fn %{id: df_id} = df ->
        file_path = File.cwd! <> "/uploaded_files/#{subscription_id}/#{deer_table_id}/#{record_id}/#{df_id}"
        {mimetype_with_newline, 0 = _exit_status} = System.cmd("file", ["--mime-type", "-b", file_path])

        Map.from_struct(df) |> Map.put(:mimetype, String.trim(mimetype_with_newline))
      end)

      IO.puts "Updating record with id #{record_id}..."

      record
      |> change
      |> cast(%{deer_files: new_deer_files}, [])
      |> cast_embed(:deer_files)
      |> Pjeski.Repo.update!
    end
  end
end
