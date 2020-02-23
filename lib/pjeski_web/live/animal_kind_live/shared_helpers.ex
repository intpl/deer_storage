defmodule PjeskiWeb.AnimalKindLive.SharedHelpers do
  alias PjeskiWeb.Router.Helpers, as: Routes
  import Phoenix.LiveView, only: [assign: 2, push_patch: 2]

  import Pjeski.UserAnimalKinds, only: [
    get_animal_kind_for_subscription!: 2,
    list_animal_kinds_for_subscription: 2,
    list_animal_kinds_for_subscription: 3,
  ]

  def search_animal_kinds(nil, _, _), do: {:error, "invalid subscription id"} # this will probably never happen, but let's keep this edge case just in case

  def search_animal_kinds(sid, nil, page), do: {:ok, list_animal_kinds_for_subscription(sid, page)}
  def search_animal_kinds(sid, "", page), do: {:ok, list_animal_kinds_for_subscription(sid, page)}
  def search_animal_kinds(sid, q, page), do: {:ok, list_animal_kinds_for_subscription(sid, q, page)}

  def patch_to_index(socket) do
    {:noreply,
     push_patch(assign(socket,
           current_animal_kind: nil,
           editing_animal_kind: nil,
           page: 1
         ), to: Routes.live_path(socket, PjeskiWeb.AnimalKindLive.Index, query: socket.assigns.query))}
  end
end
