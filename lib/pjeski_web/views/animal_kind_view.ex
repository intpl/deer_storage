defmodule PjeskiWeb.AnimalKindView do
  use PjeskiWeb, :view

  def classes_for_animal_kind_box(_, %{id: animal_kind_id}, %{id: animal_kind_id}), do: "has-background-link has-text-white"
  def classes_for_animal_kind_box(_, _, _), do: "has-background-white has-text-link is-clickable"
end
