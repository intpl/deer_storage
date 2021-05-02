defmodule DeerStorage.EctoHelpers do
  def reset_errors(changeset) do
    %{changeset | errors: [], valid?: true}
  end
end
