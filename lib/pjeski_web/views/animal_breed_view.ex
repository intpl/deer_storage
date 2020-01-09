defmodule PjeskiWeb.AnimalBreedView do
  use PjeskiWeb, :view

  def classes_for_animal_breed_box(_, %{id: animal_breed_id}, %{id: animal_breed_id}), do: "has-background-link has-text-white"
  def classes_for_animal_breed_box(_, _, _), do: "has-background-white has-text-link is-clickable"
end
