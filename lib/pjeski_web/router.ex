defmodule PjeskiWeb.Router do
  use PjeskiWeb, :router
  use Pow.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Pjeski.UserData
    plug Turbolinks
    plug NavigationHistory.Tracker
  end

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated, error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :admin do
    plug PjeskiWeb.EnsureRolePlug, :admin
  end

  scope "/", PjeskiWeb do
    pipe_through [:browser, :protected]

    scope "/admin", Admin, as: :admin do
      pipe_through [:admin]

      resources "/users", UserController do
        put "/toggle_admin", UserController, :toggle_admin
      end

      resources "/subscriptions", SubscriptionController
    end
  end

  scope "/" do
    pipe_through :browser

    pow_routes()

    get "/", PjeskiWeb.PageController, :index
  end
end
