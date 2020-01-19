defmodule PjeskiWeb.AnimalKindLive.Index do
  use Phoenix.LiveView
  alias PjeskiWeb.Router.Helpers, as: Routes
  import PjeskiWeb.Gettext

  use PjeskiWeb.LiveHelpers.RenewTokenHandler
  import Pjeski.Users.UserSessionUtils, only: [user_from_live_session: 1]
  import Pjeski.EctoHelpers, only: [reset_errors: 1]

  alias Pjeski.UserAnimalKinds.AnimalKind

  import Pjeski.UserAnimalKinds, only: [
    change_animal_kind: 1,
    change_animal_kind: 2,
    create_animal_kind_for_subscription: 2,
    delete_animal_kind_for_subscription: 2,
    get_animal_kind_for_subscription!: 2,
    list_animal_kinds_for_subscription: 2,
    list_animal_kinds_for_subscription: 3,
    per_page: 0,
    update_animal_kind_for_user: 3
  ]

  def render(assigns), do: PjeskiWeb.AnimalKindView.render("index.html", assigns)

  def mount(%{"pjeski_auth" => token}, socket) do
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

  def handle_event("close_show", _, socket), do: {:noreply, socket |> assign(current_animal_kind: nil)}
  def handle_event("close_edit", _, socket), do: {:noreply, socket |> assign(editing_animal_kind: nil)}
  def handle_event("close_new", _, socket), do: {:noreply, socket |> assign(new_animal_kind: nil)}

  def handle_event("validate_edit", %{"animal_kind" => attrs}, %{assigns: %{editing_animal_kind: animal_kind}} = socket) do
    {_, animal_kind_or_changeset} = reset_errors(animal_kind) |> change_animal_kind(attrs) |> Ecto.Changeset.apply_action(:update)
    {:noreply, socket |> assign(editing_animal_kind: change_animal_kind(animal_kind_or_changeset))}
  end

  def handle_event("save_edit", %{"animal_kind" => attrs}, %{assigns: %{editing_animal_kind: %{data: %{id: animal_kind_id}}, token: token}} = socket) do
    user = user_from_live_session(token)
    animal_kind = find_animal_kind_in_database(animal_kind_id, user.subscription_id)

    {:ok, _} = update_animal_kind_for_user(animal_kind, attrs, user_from_live_session(token))

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    redirect_to_index(socket |> put_flash(:info, gettext("animal_kind updated successfully.")))
  end

  def handle_event("save_new", %{"animal_kind" => attrs}, %{assigns: %{token: token}} = socket) do
    user = user_from_live_session(token)
    case create_animal_kind_for_subscription(attrs, user.subscription_id) do
      {:ok, _} ->
        redirect_to_index(
          socket
          # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
          |> put_flash(:info, gettext("animal_kind created successfully."))
          |> assign(new_animal_kind: nil, query: nil))

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(new_animal_kind: changeset)}
    end

  end


  def handle_event("show", %{"animal_kind_id" => animal_kind_id}, %{assigns: %{animal_kinds: animal_kinds, token: token}} = socket) do
    user = user_from_live_session(token)
    animal_kind = find_animal_kind_in_list_or_database(animal_kind_id, animal_kinds, user.subscription_id)

    {:noreply, socket |> assign(current_animal_kind: animal_kind)}
  end

  def handle_event("new", _, %{assigns: %{token: token}} = socket) do
    subscription_id = user_from_live_session(token).subscription_id

    {:noreply, socket |> assign(new_animal_kind: change_animal_kind(%AnimalKind{subscription_id: subscription_id}))}
  end

  def handle_event("edit", %{"animal_kind_id" => animal_kind_id}, %{assigns: %{animal_kinds: animal_kinds, token: token}} = socket) do
    user = user_from_live_session(token)
    animal_kind = find_animal_kind_in_list_or_database(animal_kind_id, animal_kinds, user.subscription_id)

    {:noreply, socket |> assign(editing_animal_kind: change_animal_kind(animal_kind))}
  end

  def handle_event("delete", %{"animal_kind_id" => animal_kind_id}, %{assigns: %{animal_kinds: animal_kinds, token: token}} = socket) do
    user = user_from_live_session(token)
    animal_kind = find_animal_kind_in_list_or_database(animal_kind_id, animal_kinds, user.subscription_id)
    {:ok, _} = delete_animal_kind_for_subscription(animal_kind, user.subscription_id)

    # waiting for this to get resolved: https://github.com/phoenixframework/phoenix_live_view/issues/340
    redirect_to_index(socket |> put_flash(:info, gettext("User deleted successfully.")))
  end

  def handle_event("clear", _, socket) do
    {:noreply, live_redirect(socket |> assign(page: 1), to: Routes.live_path(socket, PjeskiWeb.AnimalKindLive.Index))}
  end

  def handle_event("filter", %{"query" => query}, %{assigns: %{token: token}} = socket) when byte_size(query) <= 50 do
    user = user_from_live_session(token)
    {:ok, animal_kinds} = search_animal_kinds(user.subscription_id, query, 1)

    {:noreply, socket |> assign(animal_kinds: animal_kinds, query: query, page: 1, count: length(animal_kinds))}
  end

  def handle_event("next_page", _, %{assigns: %{page: page}} = socket), do: change_page(page + 1, socket)
  def handle_event("previous_page", _, %{assigns: %{page: page}} = socket), do: change_page(page - 1, socket)

  defp change_page(new_page, %{assigns: %{token: token, query: query}} = socket) do
    user = user_from_live_session(token)
    {:ok, animal_kinds} = search_animal_kinds(user.subscription_id, query, new_page)

    {:noreply, socket |> assign(animal_kinds: animal_kinds, page: new_page, count: length(animal_kinds))}
  end

  defp search_animal_kinds(nil, _, _), do: {:error, "invalid subscription id"} # this will probably never happen, but let's keep this edge case just in case

  defp search_animal_kinds(sid, nil, page), do: {:ok, list_animal_kinds_for_subscription(sid, page)}
  defp search_animal_kinds(sid, "", page), do: {:ok, list_animal_kinds_for_subscription(sid, page)}
  defp search_animal_kinds(sid, q, page), do: {:ok, list_animal_kinds_for_subscription(sid, q, page)}

  defp find_animal_kind_in_database(id, subscription_id), do: get_animal_kind_for_subscription!(id, subscription_id)
  defp find_animal_kind_in_list_or_database(id, animal_kinds, subscription_id) do
    id = id |> String.to_integer

    Enum.find(animal_kinds, fn animal_kind -> animal_kind.id == id end) || find_animal_kind_in_database(id, subscription_id)
  end

  defp redirect_to_index(socket) do
    {:noreply,
     live_redirect(assign(socket,
           current_animal_kind: nil,
           editing_animal_kind: nil,
           page: 1
         ), to: Routes.live_path(socket, PjeskiWeb.AnimalKindLive.Index, query: socket.assigns.query))}
  end
end
