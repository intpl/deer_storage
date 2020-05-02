defmodule PjeskiWeb.Router do
  use PjeskiWeb, :router
  use Pow.Phoenix.Router
  use Pow.Extension.Phoenix.Router, extensions: [PowResetPassword, PowEmailConfirmation, PowPersistentSession]

  import Phoenix.LiveDashboard.Router

  alias PjeskiWeb.LayoutView

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Pjeski.LocalePlug
  end

  pipeline :protected, do: plug Pow.Plug.RequireAuthenticated, error_handler: PjeskiWeb.AuthErrorHandler
  pipeline :not_authenticated, do: plug Pow.Plug.RequireNotAuthenticated, error_handler: PjeskiWeb.AuthErrorHandler
  pipeline :admin, do: plug PjeskiWeb.EnsureRolePlug, :admin

  scope "/", PjeskiWeb do
    pipe_through [:browser, :protected]

    live "/dashboard", DashboardLive.Index, layout: {LayoutView, :app}

    resources "/registration", RegistrationController, singleton: true, only: [:edit, :update]

    put "/registration/switch_subscription_id/:subscription_id", RegistrationController, :switch_subscription_id
    put "/registration/reset_subscription", RegistrationController, :reset_subscription

    resources "/session", SessionController, singleton: true, only: [:delete]
    resources "/invitation", InvitationController, only: [:new, :create]
    resources "/users", UserController, only: [:index]

    scope "/admin", Admin, as: :admin do
      pipe_through [:admin]

      live_dashboard "/phoenix", metrics: PjeskiWeb.Telemetry
      live "/dashboard", DashboardLive.Index, layout: {LayoutView, :app}  # this is in fact Admin.DashboardLive.Index

      resources "/users", UserController do
        resources "/subscription_links", UserSubscriptionLinkController, only: [:delete, :create]
        put "/subscription_links/reset", UserSubscriptionLinkController, :reset
        put "/subscription_links/make_current/:subscription_id", UserSubscriptionLinkController, :make_current

        put "/toggle_admin", UserController, :toggle_admin
        put "/log_out_from_devices", UserController, :log_out_from_devices
      end

      resources "/subscriptions", SubscriptionController
    end
  end

  scope "/", PjeskiWeb do
    pipe_through [:browser, :not_authenticated]

    resources "/session", SessionController, singleton: true, only: [:new, :create]
    resources "/registration", RegistrationController, singleton: true, only: [:new, :create]
    resources "/reset-password", ResetPasswordController, only: [:new, :create, :edit, :update]
    resources "/invitation", InvitationController, only: [:edit, :update]
  end

  scope "/", PjeskiWeb do
    pipe_through :browser

    resources "/confirm-email", ConfirmationController, only: [:show]

    get "/", PageController, :index
  end
end
