defmodule Pjeski.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  schema "users" do
    pow_user_fields()
    field :locale, LocaleEnum

    timestamps()
  end

  def changeset(user_or_changeset, params) do
    user_or_changeset
    |> pow_changeset(params)
    |> Ecto.Changeset.cast(params, [:locale])
  end
end
