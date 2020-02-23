defmodule PjeskiWeb.AnimalKindLive.EventHandlers do
  defmacro __using__(_) do
    quote do
      use Phoenix.LiveView
      import PjeskiWeb.Gettext

      alias Pjeski.UserAnimalKinds.AnimalKind
      alias PjeskiWeb.Router.Helpers, as: Routes

      import Pjeski.EctoHelpers, only: [reset_errors: 1]
      import PjeskiWeb.AnimalKindLive.SharedHelpers
      import Pjeski.Users.UserSessionUtils, only: [user_from_live_session: 1]

      import Pjeski.UserAnimalKinds, only: [
        change_animal_kind: 1,
        change_animal_kind: 2,
        create_animal_kind_for_subscription: 2,
        delete_animal_kind_for_subscription: 2,
        get_animal_kind_for_subscription!: 2,
        update_animal_kind_for_user: 3
      ]

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
        patch_to_index(socket |> put_flash(:info, gettext("animal_kind updated successfully.")))
      end

      def handle_event("save_new", %{"animal_kind" => attrs}, %{assigns: %{token: token}} = socket) do
        user = user_from_live_session(token)
        case create_animal_kind_for_subscription(attrs, user.subscription_id) do
          {:ok, _} ->
            patch_to_index(
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
        patch_to_index(socket |> put_flash(:info, gettext("User deleted successfully.")))
      end

      def handle_event("clear", _, socket) do
        {:noreply, push_redirect(socket |> assign(page: 1), to: Routes.live_path(socket, PjeskiWeb.AnimalKindLive.Index))}
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

      defp find_animal_kind_in_database(id, subscription_id), do: get_animal_kind_for_subscription!(id, subscription_id)
      defp find_animal_kind_in_list_or_database(id, animal_kinds, subscription_id) do
        id = id |> String.to_integer

        Enum.find(animal_kinds, fn animal_kind -> animal_kind.id == id end) || find_animal_kind_in_database(id, subscription_id)
      end
    end
  end
end
