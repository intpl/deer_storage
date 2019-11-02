defmodule Pjeski.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    pow_user_fields()
    field :locale, LocaleEnum
    field :displayed_name, :string

    timestamps()
  end

  def changeset(user_or_changeset, params) do
    user_or_changeset
    |> pow_changeset(params)
    |> cast(params, [:locale, :displayed_name])
    |> validate_required(:displayed_name)
    |> validate_inclusion(:locale, available_locales_atoms())
  end

  defp available_locales_atoms do
    PjeskiWeb.Gettext
    |> Gettext.known_locales()
    |> Enum.map(&String.to_atom/1)
  end
end
