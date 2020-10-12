defmodule PjeskiWeb.Router do
  use PjeskiWeb, :router

  import Phoenix.LiveDashboard.Router

  alias PjeskiWeb.LayoutView

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PjeskiWeb.LocalePlug
    plug PjeskiWeb.GetCurrentSubscriptionPlug
  end

  pipeline :uploads do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PjeskiWeb.LocalePlug
  end

  pipeline :protected, do: plug Pow.Plug.RequireAuthenticated, error_handler: PjeskiWeb.AuthErrorHandler
  pipeline :not_authenticated, do: plug Pow.Plug.RequireNotAuthenticated, error_handler: PjeskiWeb.AuthErrorHandler
  pipeline :admin, do: plug PjeskiWeb.EnsureRolePlug, :admin

  pipeline :well_known do
    plug Plug.Static, at: "/.well-known", from: {:pjeski, "priv/.well-known"}
  end

  scope "/files", PjeskiWeb do
    pipe_through [:uploads, :protected]

    post "/record/:record_id", DeerFilesController, :upload_for_record
  end

  scope "/", PjeskiWeb do
    scope "/.well-known" do
      pipe_through :well_known

      get "/*path", PageController, :not_found
    end
  end

  scope "/", PjeskiWeb do
    pipe_through [:browser, :protected]

    get "/files/record/:record_id/:file_id", DeerFilesController, :download_record

    live "/dashboard", DeerDashboardLive.Index, layout: {PjeskiWeb.LayoutView, "without_navigation.html"}
    live "/records/:table_id", DeerRecordsLive.Index, layout: {PjeskiWeb.LayoutView, "without_navigation.html"}

    resources "/registration", RegistrationController, singleton: true, only: [:edit, :update]

    put "/registration/switch_subscription_id/:subscription_id", RegistrationController, :switch_subscription_id
    put "/registration/reset_subscription_id", RegistrationController, :reset_subscription_id

    resources "/session", SessionController, singleton: true, only: [:delete]
    resources "/invitation", InvitationController, only: [:new, :create]
    resources "/users", UserController, only: [:index] do
      put "/unlink/:subscription_id", UserController, :unlink
      put "/toggle_permission/:subscription_id/:permission_key", UserController, :toggle_permission
    end

    scope "/admin", Admin, as: :admin do
      pipe_through [:admin]

      live_dashboard "/phoenix", metrics: PjeskiWeb.Telemetry
      live "/dashboard", DashboardLive.Index

      post "/users/search", UserController, :search
      resources "/users", UserController do
        resources "/subscription_links", UserSubscriptionLinkController, only: [:delete, :create]
        put "/subscription_links/reset", UserSubscriptionLinkController, :reset
        put "/subscription_links/make_current/:subscription_id", UserSubscriptionLinkController, :make_current

        put "/toggle_admin", UserController, :toggle_admin
        put "/log_out_from_devices", UserController, :log_out_from_devices
      end


      post "/subscriptions/search", SubscriptionController, :search
      resources "/subscriptions", SubscriptionController do
        resources "/subscription_links", UserSubscriptionLinkController, only: [:delete, :create]
      end
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

    live "/share/:subscription_id/:shared_record_uuid", SharedRecordsLive.Show, layout: {PjeskiWeb.LayoutView, "without_navigation.html"}
    get "/:subscription_id/shared_record/:shared_record_id/:file_id", SharedRecordFilesController, :download_file

    resources "/confirm-email", ConfirmationController, only: [:show]

    get "/", PageController, :index
  end
end
