defmodule PjeskiWeb.Admin.UserView do
  use PjeskiWeb, :view
  import PjeskiWeb.Pow.RegistrationView, only: [ languages_select_options: 0 ]

  def toggle_admin_button(conn, user) do
    text = if user.role == "admin" do
      gettext("Revoke admin privileges")
    else
      gettext("Grant admin privileges")
    end

    link text, to: Routes.admin_user_user_path(conn, :toggle_admin, user), method: :put, data: [confirm: gettext("Are you sure?")], class: "button is-warning"
  end

  def user_roles_select_options do
    [
      [gettext("Admin"), "admin"],
      [gettext("User"), "user"],
    ] |> Map.new(fn [k, v] -> {k, v} end)
  end
end
