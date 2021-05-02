defmodule DeerStorageWeb.UserView do
  use DeerStorageWeb, :view

  # admins can do whatever they want
  def link_to_toggle_permission(%{role: "admin"}, _user_permissions_link, _permission_key, _can_manage?, _current_user), do: "admin"

  # admins can click whatever they want
  def link_to_toggle_permission(user, user_permissions_link, permission_key, _can_manage?, %{role: "admin"}) do
    clickable_button(user_permissions_link, permission_key, user.id, true)
  end

  # current user can't change their permissions
  def link_to_toggle_permission(%{id: current_user_id}, user_permissions_link, permission_key, _can_manage?, %{id: current_user_id}) do
    clickable_button(user_permissions_link, permission_key, current_user_id, false)
  end

  # if current user can't manage other users
  def link_to_toggle_permission(%{id: user_id}, user_permissions_link, permission_key, false, _current_user) do
    clickable_button(user_permissions_link, permission_key, user_id, false)
  end

  # if current user can manage users
  def link_to_toggle_permission(user, user_permissions_link, permission_key, true, _current_user) do
    clickable_button(user_permissions_link, permission_key, user.id, true)
  end

  defp clickable_button(%{subscription_id: subscription_id} = user_permissions_link, permission_key, user_id, is_enabled) do
    is_permitted? = user_permissions_link[permission_key]
    classes = if is_permitted?, do: "button is-light is-success", else: "button is-light is-danger"

    button(is_permitted? |> translated_yes_or_no,
      to: Routes.user_user_path(DeerStorageWeb.Endpoint, :toggle_permission, user_id, subscription_id, permission_key),
      method: :put,
      data: [confirm: gettext("Are you sure to change this permission?")],
      class: classes,
      disabled: !is_enabled
    )
  end

  defp translated_yes_or_no(true), do: gettext("Yes")
  defp translated_yes_or_no(false), do: gettext("No")
end
