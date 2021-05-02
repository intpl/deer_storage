defmodule DeerStorage.UserAvailableSubscriptionLinks.UserAvailableSubscriptionLink do
  use Ecto.Schema
  import Ecto.Changeset

  alias DeerStorage.Users.User
  alias DeerStorage.Subscriptions.Subscription

  schema "user_available_subscription_links" do
    belongs_to :user, User
    belongs_to :subscription, Subscription
    field :permission_to_manage_users, :boolean, default: false

    timestamps()
  end

  def changeset(user_available_subscription_link, params \\ %{}) do
    user_available_subscription_link
    |> cast(params, [:user_id, :subscription_id, :permission_to_manage_users])
    |> foreign_key_constraint(:subscription_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :subscription_id],
      name: :user_id_available_subscription_id_unique_index,
      message: "Already exists"
    )
  end
end
