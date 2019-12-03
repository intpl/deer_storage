defmodule PjeskiWeb.ClientView do
  use PjeskiWeb, :view

  def classes_for_client_box(_, %{id: client_id}, %{id: client_id}), do: "has-background-link has-text-white"
  def classes_for_client_box(current_user_id, %{user_id: current_user_id}, _), do: "has-background-white has-text-link is-clickable"
  def classes_for_client_box(_, _, _), do: "has-background-light has-text-link is-clickable"
end
