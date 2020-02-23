defmodule PjeskiWeb.AnimalKindLive.Index do
  import PjeskiWeb.AnimalKindLive.SharedHelpers
  use PjeskiWeb.AnimalKindLive.EventHandlers

  use PjeskiWeb.LiveHelpers.RenewTokenHandler
  import Pjeski.Users.UserSessionUtils, only: [user_from_live_session: 1]

  import Pjeski.UserAnimalKinds, only: [per_page: 0]

  def render(assigns), do: PjeskiWeb.AnimalKindView.render("index.html", assigns)

  def mount(_params, %{"pjeski_auth" => token}, socket) do
    user = user_from_live_session(token)

    if connected?(socket), do: :timer.send_interval(1200000, self(), :renew_token) # 1200000ms = 20min

    user.locale |> Atom.to_string |> Gettext.put_locale

    {:ok, assign(socket,
        current_animal_kind: nil,
        editing_animal_kind: nil,
        new_animal_kind: nil,
        page: 1,
        per_page: per_page(),
        token: token,
        user_id: user.id
      )}
  end

  def handle_params(params, _, %{assigns: %{token: token}} = socket) do
    query = params["query"]

    case connected?(socket) do
      true ->
        user = user_from_live_session(token)
        {:ok, animal_kinds} = search_animal_kinds(user.subscription_id, query, 1)

        {:noreply, socket |> assign(animal_kinds: animal_kinds, query: query, count: length(animal_kinds))}
      false -> {:noreply, socket |> assign(query: query, animal_kinds: [], count: 0)}
    end
  end
end
