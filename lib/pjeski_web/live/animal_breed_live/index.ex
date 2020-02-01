defmodule PjeskiWeb.AnimalBreedLive.Index do
  use Phoenix.LiveView
  alias PjeskiWeb.Router.Helpers, as: Routes
  import PjeskiWeb.Gettext

  use PjeskiWeb.LiveHelpers.RenewTokenHandler
  import Pjeski.Users.UserSessionUtils, only: [user_from_live_session: 1]
  import Pjeski.EctoHelpers, only: [reset_errors: 1]

  alias Pjeski.UserAnimalKinds
  alias Pjeski.UserAnimalBreeds.AnimalBreed

  import Pjeski.UserAnimalBreeds, only: [
    change_animal_breed: 1,
    change_animal_breed: 2,
    create_animal_breed_for_subscription: 2,
    delete_animal_breed_for_subscription: 2,
    get_animal_breed_for_subscription!: 2,
    list_animal_breeds_for_subscription: 2,
    list_animal_breeds_for_subscription: 3,
    list_animal_breeds_for_animal_kind_and_subscription: 3,
    list_animal_breeds_for_animal_kind_and_subscription: 4,
    per_page: 0,
    update_animal_breed_for_user: 3
  ]

  def render(assigns), do: PjeskiWeb.AnimalBreedView.render("index.html", assigns)

  def mount(_params, %{"pjeski_auth" => token}, socket) do
    user = user_from_live_session(token)

    if connected?(socket), do: :timer.send_interval(1200000, self(), :renew_token) # 1200000ms = 20min

    user.locale |> Atom.to_string |> Gettext.put_locale

    {:ok, assign(socket,
        current_animal_breed: nil,
        editing_animal_breed: nil,
        new_animal_breed: nil,
        page: 1,
        per_page: per_page(),
        token: token,
        user_id: user.id,
        animal_kinds_options: load_animal_kinds_options(user.subscription_id),
        selected_animal_kind_filter: nil
      )}
  end

  def handle_params(params, _, %{assigns: %{token: token, animal_kinds_options: animal_kinds_options}} = socket) do
    query = params["query"]
    ak_id = id_from_options(animal_kinds_options, params["ak_id"])

    case connected?(socket) do
      true ->
        user = user_from_live_session(token)
        {:ok, animal_breeds} = search_animal_breeds_for_animal_kind(ak_id, user.subscription_id, query, 1)

        {:noreply, socket |> assign(animal_breeds: animal_breeds, query: query, count: length(animal_breeds), selected_animal_kind_filter: ak_id)}
      false -> {:noreply, socket |> assign(query: query, animal_breeds: [], count: 0)}
    end
  end

  def handle_event("close_show", _, socket), do: {:noreply, socket |> assign(current_animal_breed: nil)}
  def handle_event("close_edit", _, socket), do: {:noreply, socket |> assign(editing_animal_breed: nil)}
  def handle_event("close_new", _, socket), do: {:noreply, socket |> assign(new_animal_breed: nil)}

  def handle_event("validate_edit", %{"animal_breed" => attrs}, %{assigns: %{editing_animal_breed: animal_breed}} = socket) do
    {_, animal_breed_or_changeset} = reset_errors(animal_breed) |> change_animal_breed(attrs) |> Ecto.Changeset.apply_action(:update)
    {:noreply, socket |> assign(editing_animal_breed: change_animal_breed(animal_breed_or_changeset))}
  end

  def handle_event("save_edit", %{"animal_breed" => attrs}, %{assigns: %{editing_animal_breed: %{data: %{id: animal_breed_id}}, token: token}} = socket) do
    user = user_from_live_session(token)
    animal_breed = find_animal_breed_in_database(animal_breed_id, user.subscription_id)

    {:ok, _} = update_animal_breed_for_user(animal_breed, attrs, user_from_live_session(token))

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    patch_to_index(socket |> put_flash(:info, gettext("Animal breed updated successfully.")))
  end

  def handle_event("save_new", %{"animal_breed" => attrs}, %{assigns: %{token: token}} = socket) do
    user = user_from_live_session(token)
    case create_animal_breed_for_subscription(attrs, user.subscription_id) do
      {:ok, _} ->
        patch_to_index(
          socket
          # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
          |> put_flash(:info, gettext("Animal breed created successfully."))
          |> assign(new_animal_breed: nil))

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(new_animal_breed: changeset)}
    end

  end


  def handle_event("show", %{"animal_breed_id" => animal_breed_id}, %{assigns: %{animal_breeds: animal_breeds, token: token}} = socket) do
    user = user_from_live_session(token)
    animal_breed = find_animal_breed_in_list_or_database(animal_breed_id, animal_breeds, user.subscription_id)

    {:noreply, socket |> assign(current_animal_breed: animal_breed)}
  end

  def handle_event("new", _, %{assigns: %{token: token}} = socket) do
    subscription_id = user_from_live_session(token).subscription_id

    {:noreply, socket |> assign(new_animal_breed: change_animal_breed(%AnimalBreed{subscription_id: subscription_id}))}
  end

  def handle_event("edit", %{"animal_breed_id" => animal_breed_id}, %{assigns: %{animal_breeds: animal_breeds, token: token}} = socket) do
    user = user_from_live_session(token)
    animal_breed = find_animal_breed_in_list_or_database(animal_breed_id, animal_breeds, user.subscription_id)

    {:noreply, socket |> assign(editing_animal_breed: change_animal_breed(animal_breed))}
  end

  def handle_event("delete", %{"animal_breed_id" => animal_breed_id}, %{assigns: %{animal_breeds: animal_breeds, token: token}} = socket) do
    user = user_from_live_session(token)
    animal_breed = find_animal_breed_in_list_or_database(animal_breed_id, animal_breeds, user.subscription_id)
    {:ok, _} = delete_animal_breed_for_subscription(animal_breed, user.subscription_id)

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    patch_to_index(socket |> put_flash(:info, gettext("animal breed deleted successfully.")))
  end

  def handle_event("clear", _, %{assigns: %{token: token}} = socket) do
    {:noreply, push_redirect(
      socket |> assign(
          animal_kinds_options: user_from_live_session(token).subscription_id |> load_animal_kinds_options,
          selected_animal_kind_filter: nil,
          page: 1
      ),
        to: Routes.live_path(socket, PjeskiWeb.AnimalBreedLive.Index)
      )}
  end

  def handle_event("filter", %{"query" => query, "ak_id" => animal_kind_id_string}, %{assigns: %{token: token, selected_animal_kind_filter: selected_animal_kind_filter, animal_kinds_options: animal_kinds_options}} = socket) when byte_size(query) <= 50 do
    user = user_from_live_session(token)
    ak_id = id_from_options(animal_kinds_options, (animal_kind_id_string ||selected_animal_kind_filter))

    {:ok, animal_breeds} = search_animal_breeds_for_animal_kind(ak_id, user.subscription_id, query, 1)

    {:noreply, socket |> assign(
        animal_breeds: animal_breeds,
        count: length(animal_breeds),
        page: 1,
        query: query,
        selected_animal_kind_filter: ak_id
      )}
  end

  def handle_event("next_page", _, %{assigns: %{page: page}} = socket), do: change_page(page + 1, socket)
  def handle_event("previous_page", _, %{assigns: %{page: page}} = socket), do: change_page(page - 1, socket)

  defp change_page(new_page, %{assigns: %{token: token, query: query, selected_animal_kind_filter: selected_animal_kind_filter, animal_kinds_options: animal_kinds_options}} = socket) do
    user = user_from_live_session(token)
    ak_id = id_from_options(animal_kinds_options, selected_animal_kind_filter)

    {:ok, animal_breeds} = search_animal_breeds_for_animal_kind(ak_id, user.subscription_id, query, new_page)

    {:noreply, socket |> assign(animal_breeds: animal_breeds, page: new_page, count: length(animal_breeds))}
  end

  defp search_animal_breeds_for_animal_kind(_, nil, _, _), do: {:error, "invalid subscription id"} # this will probably never happen, but let's keep this edge case just in case

  defp search_animal_breeds_for_animal_kind(nil, sid, nil, page), do: {:ok, list_animal_breeds_for_subscription(sid, page)}
  defp search_animal_breeds_for_animal_kind(nil, sid, "", page), do: {:ok, list_animal_breeds_for_subscription(sid, page)}
  defp search_animal_breeds_for_animal_kind(nil, sid, q, page), do: {:ok, list_animal_breeds_for_subscription(sid, q, page)}

  defp search_animal_breeds_for_animal_kind(ak_id, sid, nil, page), do: {:ok, list_animal_breeds_for_animal_kind_and_subscription(ak_id, sid, page)}
  defp search_animal_breeds_for_animal_kind(ak_id, sid, "", page), do: {:ok, list_animal_breeds_for_animal_kind_and_subscription(ak_id, sid, page)}
  defp search_animal_breeds_for_animal_kind(ak_id, sid, q, page), do: {:ok, list_animal_breeds_for_animal_kind_and_subscription(ak_id, sid, q, page)}

  defp find_animal_breed_in_database(id, subscription_id), do: get_animal_breed_for_subscription!(id, subscription_id)
  defp find_animal_breed_in_list_or_database(id, animal_breeds, subscription_id) do
    id = id |> String.to_integer

    Enum.find(animal_breeds, fn animal_breed -> animal_breed.id == id end) || find_animal_breed_in_database(id, subscription_id)
  end

  defp load_animal_kinds_options(subscription_id) do
    subscription_id
    |> UserAnimalKinds.pluck_animal_kinds_structs_for_subscription
    |> Enum.map(fn struct -> { struct.name, struct.id} end)
  end

  defp id_from_options(_, nil), do: nil
  defp id_from_options(_, ""), do: nil
  defp id_from_options(animal_kinds_options, id) when is_bitstring(id), do: id_from_options(animal_kinds_options, String.to_integer(id))
  defp id_from_options(animal_kinds_options, ak_id) do
    { _name, ak_id } = Enum.find(animal_kinds_options, fn {_name, id} -> id == ak_id end)

    ak_id
  end

  defp patch_to_index(%{assigns: %{query: query, selected_animal_kind_filter: selected_animal_kind_filter}} = socket) do
    {:noreply,
     push_patch(assign(socket,
           current_animal_breed: nil,
           editing_animal_breed: nil,
           page: 1
         ), to: Routes.live_path(socket, PjeskiWeb.AnimalBreedLive.Index, query: query, ak_id: selected_animal_kind_filter))}
  end
end
