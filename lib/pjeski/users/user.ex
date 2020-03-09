defmodule Pjeski.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  import Pow.Ecto.Schema.Changeset, only: [new_password_changeset: 3, user_id_field_changeset: 3]
  import Ecto.Changeset

  alias Pjeski.Subscriptions.Subscription

  schema "users" do
    field :locale, :string
    field :name, :string
    field :time_zone, :string, default: "Europe/Warsaw"
    field :admin_notes, :string
    field :role, :string, default: "user"
    belongs_to :subscription, Subscription

    pow_user_fields()

    timestamps()
  end

  # TODO extract validations in separate common function
  def admin_changeset(user_or_changeset, params) do
    user_or_changeset
    |> cast(params, [:locale, :name, :role, :admin_notes, :subscription_id, :time_zone])
    |> new_password_changeset(params, @pow_config)
    |> user_id_field_changeset(params, @pow_config)
    |> validate_required([:name])
    |> validate_inclusion(:locale, available_locales_strings())
    |> validate_inclusion(:time_zone, Tzdata.zone_list)
    |> validate_role()
  end

  def changeset(%{role: "admin"} = existing_user, params), do: user_changeset(existing_user, params)
  def changeset(%{subscription_id: subscription_id} = existing_user, params) when is_number(subscription_id) do
    user_changeset(existing_user, params)
  end
  def changeset(user_or_changeset, params) do
    user_changeset(user_or_changeset, params)
    |> cast_assoc(:subscription, with: &Subscription.changeset/2)
    |> validate_required(:subscription)
  end

  def changeset_role(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:role])
    |> validate_role()
  end

  defp validate_role(changeset) do
    Ecto.Changeset.validate_inclusion(changeset, :role, ~w(user admin))
  end

  defp available_locales_strings do
    PjeskiWeb.Gettext |> Gettext.known_locales()
  end

  defp user_changeset(user_or_changeset, params) do
    user_or_changeset
    |> pow_changeset(params)
    |> cast(params, [:locale, :name, :time_zone])
    |> validate_required([:name, :email])
    |> validate_length(:name, min: 3)
    |> validate_length(:name, max: 100)
    |> validate_length(:email, min: 3)
    |> validate_length(:email, max: 100)
    |> validate_inclusion(:locale, available_locales_strings())
    |> validate_inclusion(:time_zone, Tzdata.zone_list)
  end
end
