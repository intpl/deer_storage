defmodule PjeskiWeb.AnimalView do
  use PjeskiWeb, :view

  def clear_or_refresh(_query, id) when is_integer(id), do: gettext("Clear")
  def clear_or_refresh(nil, _id), do: gettext("Refresh")
  def clear_or_refresh("", _id), do: gettext("Refresh")
  def clear_or_refresh(_query, _id), do: gettext("Clear")

  def classes_for_animal_box(_, %{id: animal_id}, %{id: animal_id}), do: "has-background-link has-text-white"
  def classes_for_animal_box(_, _, _), do: "has-background-white has-text-link is-clickable"
end
