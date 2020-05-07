defmodule Pjeski.DeerRecords do
  import Ecto.Query, warn: false
  alias Pjeski.Repo
  alias Pjeski.DeerRecords.DeerRecord

  def create_record(attrs, subscription_id) do
    %DeerRecord{subscription_id: subscription_id} |> DeerRecord.changeset(attrs) |> Repo.insert()
  end
end
