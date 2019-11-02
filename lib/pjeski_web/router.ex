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
  end

  scope "/", PjeskiWeb do
    pipe_through [:browser, :protected]

    # Add your protected routes here
  end

  scope "/" do
    pipe_through :browser

    pow_routes()

    get "/", PjeskiWeb.PageController, :index
  end
end
