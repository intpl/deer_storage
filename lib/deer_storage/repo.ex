defmodule DeerStorage.Repo do
  use Ecto.Repo,
    otp_app: :deer_storage,
    adapter: Ecto.Adapters.Postgres
end
