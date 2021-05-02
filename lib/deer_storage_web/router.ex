defmodule DeerStorageWeb.Router do
  use DeerStorageWeb, :router

  import Phoenix.LiveDashboard.Router

  alias DeerStorageWeb.LayoutView

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug DeerStorageWeb.LocalePlug
    plug DeerStorageWeb.GetCurrentSubscriptionPlug
  end

  pipeline :protected, do: plug Pow.Plug.RequireAuthenticated, error_handler: DeerStorageWeb.AuthErrorHandler
  pipeline :not_authenticated, do: plug Pow.Plug.RequireNotAuthenticated, error_handler: DeerStorageWeb.AuthErrorHandler
  pipeline :admin, do: plug DeerStorageWeb.EnsureRolePlug, :admin
  pipeline :navigation_tracked, do: plug NavigationHistory.Tracker, history_size: 1

  scope "/", DeerStorageWeb do
    pipe_through [:browser, :protected]

    get "/files/record/:record_id/:file_id", DeerFilesController, :download_record

    live "/dashboard", DeerDashboardLive.Index, layout: {DeerStorageWeb.LayoutView, "without_navigation.html"}
    live "/records/:table_id", DeerRecordsLive.Index, layout: {DeerStorageWeb.LayoutView, "without_navigation.html"}

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

      live_dashboard "/phoenix",
        metrics: DeerStorageWeb.Telemetry,
        metrics_history: {DeerStorageWeb.MetricsStorage, :metrics_history, []},
        ecto_repos: [DeerStorage.Repo]

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

  scope "/", DeerStorageWeb do
    pipe_through [:browser, :not_authenticated, :navigation_tracked]

    resources "/session", SessionController, singleton: true, only: [:new, :create]
    resources "/registration", RegistrationController, singleton: true, only: [:new, :create]
    resources "/reset-password", ResetPasswordController, only: [:new, :create, :edit, :update]
    resources "/invitation", InvitationController, only: [:edit, :update]
  end

  scope "/", DeerStorageWeb do
    pipe_through [:browser, :navigation_tracked]

    live "/share/:subscription_id/:shared_record_uuid", SharedRecordsLive.Show, layout: {DeerStorageWeb.LayoutView, "without_navigation.html"}
    get "/:subscription_id/shared_record/:shared_record_id/:file_id", SharedRecordFilesController, :download_file_from_shared_record
    get "/:subscription_id/shared_file/:shared_file_id/:file_id", SharedRecordFilesController, :download_file_from_shared_file
    post "/change_language", ChangeLanguageController, :change_language

    resources "/confirm-email", ConfirmationController, only: [:show]

    get "/", PageController, :index
  end
end
