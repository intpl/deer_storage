defmodule DeerStorageWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use DeerStorageWeb, :controller
      use DeerStorageWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, formats: [html: "View"]
      plug :put_layout, html: {DeerStorageWeb.LayoutView, :app}

      import Plug.Conn
      use Gettext, backend: DeerStorageWeb.Gettext
      import Phoenix.LiveView.Controller

      alias DeerStorageWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/deer_storage_web/templates",
        namespace: DeerStorageWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [view_module: 1, get_csrf_token: 0]

      import Phoenix.Flash

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import DeerStorageWeb.ErrorHelpers
      use Gettext, backend: DeerStorageWeb.Gettext
      alias DeerStorageWeb.Router.Helpers, as: Routes

      import DeerStorageWeb.DateHelpers

      import Phoenix.Component,
        only: [
          live_component: 1,
          live_file_input: 1,
          live_render: 2,
          live_render: 3
        ]
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller

      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      use Gettext, backend: DeerStorageWeb.Gettext
    end
  end

  def mailer_view do
    quote do
      use Phoenix.View, root: "lib/deer_storage_web/templates", namespace: DeerStorageWeb
      use Phoenix.HTML
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
