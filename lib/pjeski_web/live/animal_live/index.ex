defmodule PjeskiWeb.AnimalLive.Index do
  use Phoenix.LiveView
  alias PjeskiWeb.Router.Helpers, as: Routes
  import PjeskiWeb.Gettext

  use PjeskiWeb.LiveHelpers.RenewTokenHandler
  import Pjeski.Users.UserSessionUtils, only: [user_from_live_session: 1]
  import Pjeski.EctoHelpers, only: [reset_errors: 1]

  alias Pjeski.UserAnimalKinds
  alias Pjeski.UserAnimalBreeds
  alias Pjeski.UserAnimals.Animal

  import Pjeski.UserAnimals, only: [
    change_animal: 1,
    change_animal: 2,
    create_animal_for_user: 2,
    delete_animal_for_subscription: 2,
    get_animal_for_subscription!: 2,
    list_animals_for_subscription: 2,
    list_animals_for_subscription: 3,
    list_animals_for_animal_kind_and_breed_and_subscription: 4,
    list_animals_for_animal_kind_and_breed_and_subscription: 5,
    list_animals_for_animal_kind_and_subscription: 3,
    list_animals_for_animal_kind_and_subscription: 4,
    per_page: 0,
    update_animal_for_user: 3
  ]

  def render(assigns), do: PjeskiWeb.AnimalView.render("index.html", assigns)

  def mount(params, %{"pjeski_auth" => token}, socket) do
    user = user_from_live_session(token)

    if connected?(socket), do: :timer.send_interval(1200000, self(), :renew_token) # 1200000ms = 20min

    user.locale |> Atom.to_string |> Gettext.put_locale

    {:ok, assign(socket,
        current_animal: nil,
        editing_animal: nil,
        new_animal: nil,
        page: 1,
        per_page: per_page(),
        token: token,
        user_id: user.id,
        animal_kinds_options: load_animal_kinds_options(user.subscription_id),
        animal_breeds_options: load_animal_breeds_options(params["ak_id"], user.subscription_id),
        selected_animal_kind_filter: nil,
        selected_animal_breed_filter: nil
      )}
  end

  def handle_params(params, _, %{assigns: %{token: token, animal_kinds_options: animal_kinds_options, animal_breeds_options: animal_breeds_options}} = socket) do
    query = params["query"]
    ak_id = id_from_options(animal_kinds_options, params["ak_id"])
    ab_id = id_from_options(animal_breeds_options, params["ab_id"])

    case connected?(socket) do
      true ->
        user = user_from_live_session(token)
        animal_breeds_options = load_animal_breeds_options(ak_id, user.subscription_id)

        {:ok, animals} = search_animals_for_animal_kind_and_animal_breed(ak_id, ab_id, user.subscription_id, query, 1)

        {:noreply, socket |> assign(animals: animals, query: query, count: length(animals), selected_animal_kind_filter: ak_id, selected_animal_breed_filter: ab_id, animal_breeds_options: animal_breeds_options)}
      false -> {:noreply, socket |> assign(query: query, animals: [], count: 0)}
    end
  end

  def handle_event("close_show", _, socket), do: {:noreply, socket |> assign(current_animal: nil)}
  def handle_event("close_edit", _, socket), do: {:noreply, socket |> assign(editing_animal: nil)}
  def handle_event("close_new", _, socket), do: {:noreply, socket |> assign(new_animal: nil)}

  def handle_event("validate_edit", %{"animal" => attrs}, %{assigns: %{editing_animal: animal}} = socket) do
    {_, animal_or_changeset} = reset_errors(animal) |> change_animal(attrs) |> Ecto.Changeset.apply_action(:update)
    {:noreply, socket |> assign(editing_animal: change_animal(animal_or_changeset))}
  end

  def handle_event("save_edit", %{"animal" => attrs}, %{assigns: %{editing_animal: %{data: %{id: animal_id}}, token: token}} = socket) do
    user = user_from_live_session(token)
    animal = find_animal_in_database(animal_id, user.subscription_id)

    {:ok, _} = update_animal_for_user(animal, attrs, user_from_live_session(token))

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    patch_to_index(socket |> put_flash(:info, gettext("Animal updated successfully.")))
  end

  def handle_event("save_new", %{"animal" => attrs}, %{assigns: %{token: token}} = socket) do
    user = user_from_live_session(token)
    case create_animal_for_user(attrs, user) do
      {:ok, _} ->
        patch_to_index(
          socket
          # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
          |> put_flash(:info, gettext("Animal created successfully."))
          |> assign(new_animal: nil))

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(new_animal: changeset)}
    end

  end


  def handle_event("show", %{"animal_id" => animal_id}, %{assigns: %{animals: animals, token: token}} = socket) do
    user = user_from_live_session(token)
    animal = find_animal_in_list_or_database(animal_id, animals, user.subscription_id)

    {:noreply, socket |> assign(current_animal: animal)}
  end

  def handle_event("new", _, %{assigns: %{token: token}} = socket) do
    subscription_id = user_from_live_session(token).subscription_id

    {:noreply, socket |> assign(new_animal: change_animal(%Animal{subscription_id: subscription_id}))}
  end

  def handle_event("edit", %{"animal_id" => animal_id}, %{assigns: %{animals: animals, token: token}} = socket) do
    user = user_from_live_session(token)
    animal = find_animal_in_list_or_database(animal_id, animals, user.subscription_id)

    {:noreply, socket |> assign(editing_animal: change_animal(animal))}
  end

  def handle_event("delete", %{"animal_id" => animal_id}, %{assigns: %{animals: animals, token: token}} = socket) do
    user = user_from_live_session(token)
    animal = find_animal_in_list_or_database(animal_id, animals, user.subscription_id)
    {:ok, _} = delete_animal_for_subscription(animal, user.subscription_id)

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    patch_to_index(socket |> put_flash(:info, gettext("Animal deleted successfully.")))
  end

  def handle_event("clear", _, %{assigns: %{token: token}} = socket) do
    {:noreply, push_redirect(
      socket |> assign(
          animal_kinds_options: user_from_live_session(token).subscription_id |> load_animal_kinds_options,
          animal_breeds_options: [],
          selected_animal_kind_filter: nil,
          selected_animal_breed_filter: nil,
          page: 1
      ),
        to: Routes.live_path(socket, PjeskiWeb.AnimalLive.Index)
      )}
  end

  def handle_event("filter", %{"query" => query,
                               "ak_id" => animal_kind_id_string,
                               "ab_id" => animal_breed_id_string
                              }, %{assigns: %{
                                      token: token,
                                      selected_animal_breed_filter: previous_animal_breed_filter,
                                      selected_animal_kind_filter: previous_animal_kind_filter,
                                      animal_kinds_options: animal_kinds_options,
                                      animal_breeds_options: animal_breeds_options
                                   }} = socket) when byte_size(query) <= 50 do

    user = user_from_live_session(token)


    ak_id = id_from_options(animal_kinds_options, (animal_kind_id_string || previous_animal_kind_filter))
    { maybe_new_animal_breeds_options, ab_id } = case previous_animal_kind_filter == ak_id do
                                                   false -> { load_animal_breeds_options(ak_id, user.subscription_id), nil }
                                                   _ -> { animal_breeds_options,
                                                   id_from_options(animal_breeds_options, (animal_breed_id_string || previous_animal_breed_filter)) }
                                                 end

    {:ok, animals} = search_animals_for_animal_kind_and_animal_breed(ak_id, ab_id, user.subscription_id, query, 1)

    {:noreply, socket |> assign(
        animal_breeds_options: maybe_new_animal_breeds_options,
        animals: animals,
        count: length(animals),
        page: 1,
        query: query,
        selected_animal_breed_filter: ab_id,
        selected_animal_kind_filter: ak_id
      )}
  end

  def handle_event("next_page", _, %{assigns: %{page: page}} = socket), do: change_page(page + 1, socket)
  def handle_event("previous_page", _, %{assigns: %{page: page}} = socket), do: change_page(page - 1, socket)

  defp change_page(new_page, %{assigns: %{token: token, query: query, selected_animal_breed_filter: selected_animal_breed_filter, selected_animal_kind_filter: selected_animal_kind_filter, animal_breeds_options: animal_breeds_options, animal_kinds_options: animal_kinds_options}} = socket) do
    user = user_from_live_session(token)
    ak_id = id_from_options(animal_kinds_options, selected_animal_kind_filter)
    ab_id = id_from_options(animal_breeds_options, selected_animal_breed_filter)

    {:ok, animals} = search_animals_for_animal_kind_and_animal_breed(ak_id, ab_id, user.subscription_id, query, new_page)

    {:noreply, socket |> assign(animals: animals, page: new_page, count: length(animals))}
  end

  defp search_animals_for_animal_kind_and_animal_breed(_, _, nil, _, _), do: {:error, "invalid subscription id"} # this will probably never happen, but let's keep this edge case just in case

  defp search_animals_for_animal_kind_and_animal_breed(nil, nil, sid, nil, page), do: {:ok, list_animals_for_subscription(sid, page)}
  defp search_animals_for_animal_kind_and_animal_breed(nil, nil, sid, "", page), do: {:ok, list_animals_for_subscription(sid, page)}
  defp search_animals_for_animal_kind_and_animal_breed(nil, nil, sid, q, page), do: {:ok, list_animals_for_subscription(sid, q, page)}

  defp search_animals_for_animal_kind_and_animal_breed(ak_id, nil, sid, nil, page), do: {:ok, list_animals_for_animal_kind_and_subscription(ak_id, sid, page)}
  defp search_animals_for_animal_kind_and_animal_breed(ak_id, nil, sid, "", page), do: {:ok, list_animals_for_animal_kind_and_subscription(ak_id, sid, page)}
  defp search_animals_for_animal_kind_and_animal_breed(ak_id, nil, sid, q, page), do: {:ok, list_animals_for_animal_kind_and_subscription(ak_id, sid, q, page)}

  defp search_animals_for_animal_kind_and_animal_breed(ak_id, ab_id, sid, nil, page), do: {:ok, list_animals_for_animal_kind_and_breed_and_subscription(ak_id, ab_id, sid, page)}
  defp search_animals_for_animal_kind_and_animal_breed(ak_id, ab_id, sid, "", page), do: {:ok, list_animals_for_animal_kind_and_breed_and_subscription(ak_id, ab_id, sid, page)}
  defp search_animals_for_animal_kind_and_animal_breed(ak_id, ab_id, sid, q, page), do: {:ok, list_animals_for_animal_kind_and_breed_and_subscription(ak_id, ab_id, sid, q, page)}

  defp find_animal_in_database(id, subscription_id), do: get_animal_for_subscription!(id, subscription_id)
  defp find_animal_in_list_or_database(id, animals, subscription_id) do
    id = id |> String.to_integer

    Enum.find(animals, fn animal -> animal.id == id end) || find_animal_in_database(id, subscription_id)
  end

  defp load_animal_kinds_options(subscription_id) do
    subscription_id
    |> UserAnimalKinds.pluck_animal_kinds_structs_for_subscription
    |> Enum.map(fn struct -> { struct.name, struct.id} end)
  end

  defp load_animal_breeds_options("", _subscription_id), do: []
  defp load_animal_breeds_options(nil, _subscription_id), do: []
  defp load_animal_breeds_options(ak_id, subscription_id) when is_bitstring(ak_id), do: load_animal_breeds_options(String.to_integer(ak_id), subscription_id)
  defp load_animal_breeds_options(ak_id, subscription_id) do
    UserAnimalBreeds.pluck_animal_breeds_structs_for_animal_kind_and_subscription(ak_id, subscription_id)
    |> Enum.map(fn struct -> { struct.name, struct.id} end)
  end

  # TODO extract this as it is common to animal breeds
  defp id_from_options(_, nil), do: nil
  defp id_from_options(_, ""), do: nil
  defp id_from_options(options, id) when is_bitstring(id), do: id_from_options(options, String.to_integer(id))
  defp id_from_options(options, requested_id) do
    case Enum.find(options, fn {_name, id} -> id == requested_id end) do
      { _name, requested_id } -> requested_id
      _ -> nil
    end
  end

  defp patch_to_index(%{assigns: %{query: query, selected_animal_kind_filter: selected_animal_kind_filter}} = socket) do
    {:noreply,
     push_patch(assign(socket,
           current_animal: nil,
           editing_animal: nil,
           page: 1
         ), to: Routes.live_path(socket, PjeskiWeb.AnimalLive.Index, query: query, ak_id: selected_animal_kind_filter))}
  end
end
