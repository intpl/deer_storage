defmodule Pjeski.Repo do
  use Ecto.Repo,
    otp_app: :pjeski,
    adapter: Ecto.Adapters.Postgres
end
