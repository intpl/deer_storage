defmodule Pjeski.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  import Pow.Ecto.Schema.Changeset, only: [new_password_changeset: 3]
  import Ecto.Changeset

  schema "users" do
    field :locale, LocaleEnum
    field :displayed_name, :string
    field :role, :string, default: "user"

    pow_user_fields()

    timestamps()
  end

  def admin_changeset(user_or_changeset, params) do
    user_or_changeset
    |> cast(params, [:locale, :displayed_name, :role, :email])
    |> validate_required(:displayed_name)
    |> validate_inclusion(:locale, available_locales_atoms())
    |> validate_role()
    |> new_password_changeset(params, @pow_config)
  end

  def changeset(user_or_changeset, params) do
    user_or_changeset
    |> pow_changeset(params)
    |> cast(params, [:locale, :displayed_name])
    |> validate_required(:displayed_name)
    |> validate_inclusion(:locale, available_locales_atoms())
    |> validate_role()
  end

  def changeset_role(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:role])
    |> validate_role()
  end

  defp validate_role(changeset) do
    Ecto.Changeset.validate_inclusion(changeset, :role, ~w(user admin))
  end

  defp available_locales_atoms do
    PjeskiWeb.Gettext
    |> Gettext.known_locales()
    |> Enum.map(&String.to_atom/1)
  end
end
