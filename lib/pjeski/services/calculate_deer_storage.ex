defmodule Pjeski.Services.CalculateDeerStorage do
  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.Repo
  import Ecto.Query, warn: false

  import Pjeski.DeerRecords.DeerRecord, only: [deer_files_stats: 1]

  def run! do
    minimal_records = Repo.all(
      from r in DeerRecord, select: [:subscription_id, :deer_files], where: fragment("cardinality(?) > 0", field(r, :deer_files)))

    Enum.reduce(minimal_records, %{}, fn dr, acc_map ->
      {total_files, total_kilobytes} = acc_map[dr.subscription_id] || {0, 0}
      {dr_files, dr_kilobytes} = deer_files_stats(dr)

      Map.merge(acc_map, %{dr.subscription_id => {total_files + dr_files, total_kilobytes + dr_kilobytes}})
    end)
  end
end
