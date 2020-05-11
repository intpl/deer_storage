defmodule PjeskiWeb.DeerRecordView do
  use PjeskiWeb, :view

  def classes_for_record_box(_, %{id: record_id}, %{id: record_id}), do: "has-background-link has-text-white"
  def classes_for_record_box(current_user_id, %{user_id: current_user_id}, _), do: "has-background-white has-text-link is-clickable"
  def classes_for_record_box(_, _, _), do: "has-background-light has-text-link is-clickable"
end
