defmodule DeerStorageWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :deer_storage

  @session_options store: :cookie, key: "_session_key", signing_salt: "KLHKFqia"

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :deer_storage,
    gzip: true,
    only: ~w(css fonts images js favicon.ico robots.txt ViewerJS)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    # 256MB
    parsers: [:urlencoded, {:multipart, length: 268_435_456}, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session, @session_options

  plug Pow.Plug.Session, otp_app: :deer_storage
  plug PowPersistentSession.Plug.Cookie

  plug DeerStorageWeb.Router
end
