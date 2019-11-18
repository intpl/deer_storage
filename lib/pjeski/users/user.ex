defmodule Pjeski.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  import Pow.Ecto.Schema.Changeset, only: [new_password_changeset: 3, user_id_field_changeset: 3]
  import Ecto.Changeset

  alias Pjeski.Subscriptions.Subscription

  schema "users" do
    field :locale, LocaleEnum
    field :name, :string
    field :admin_notes, :string
    field :role, :string, default: "user"
    belongs_to :subscription, Subscription

    pow_user_fields()

    timestamps()
  end

  # TODO extract validations in separate common function
  def admin_changeset(user_or_changeset, params) do
    user_or_changeset
    |> cast(params, [:locale, :name, :role, :admin_notes, :subscription_id])
    |> new_password_changeset(params, @pow_config)
    |> user_id_field_changeset(params, @pow_config)
    |> validate_required([:name])
    |> validate_inclusion(:locale, available_locales_atoms())
    |> validate_role()
  end

  # TODO extract validations in separate common function
  def changeset(user_or_changeset, params) do
    user_or_changeset
    |> pow_changeset(params)
    |> cast(params, [:locale, :name])
    |> validate_required([:name, :email])
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
