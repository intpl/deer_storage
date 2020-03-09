defmodule PjeskiWeb.Router do
  use PjeskiWeb, :router
  use Pow.Phoenix.Router

  alias PjeskiWeb.LayoutView

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Pjeski.UserDataPlug
    plug NavigationHistory.Tracker
  end

  pipeline :protected, do: plug Pow.Plug.RequireAuthenticated, error_handler: PjeskiWeb.AuthErrorHandler
  pipeline :not_authenticated, do: plug Pow.Plug.RequireNotAuthenticated, error_handler: PjeskiWeb.AuthErrorHandler

  pipeline :admin do
    plug PjeskiWeb.EnsureRolePlug, :admin
  end

  scope "/", PjeskiWeb do
    pipe_through [:browser, :protected]

    live "/dashboard", DashboardLive.Index, layout: {LayoutView, :app}

    resources "/registration", RegistrationController, singleton: true, only: [:edit, :update]
    resources "/session", SessionController, singleton: true, only: [:delete]

    scope "/admin", Admin, as: :admin do
      pipe_through [:admin]

      live "/dashboard", DashboardLive.Index, layout: {LayoutView, :app}  # this is in fact Admin.DashboardLive.Index

      resources "/users", UserController do
        put "/toggle_admin", UserController, :toggle_admin
        put "/log_out_from_devices", UserController, :log_out_from_devices
      end

      resources "/subscriptions", SubscriptionController
    end
  end

  scope "/" do
    pipe_through [:browser, :not_authenticated]

    resources "/session",
      PjeskiWeb.SessionController,
      singleton: true,
      only: [:new, :create]

    resources "/registration",
      PjeskiWeb.RegistrationController,
      singleton: true,
      only: [:new, :create]
  end

  scope "/" do
    pipe_through :browser

    # pow_extension_routes()

    get "/", PjeskiWeb.PageController, :index
  end
end
