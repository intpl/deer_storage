defmodule DeerStorage.UsersTest do
  use DeerStorage.DataCase

  alias DeerStorage.Users
  alias DeerStorage.Users.User

  @valid_attrs %{
    email: "test@example.org",
    name: "Henryk Testowny",
    password: "secret123",
    password_confirmation: "secret123",
    time_zone: "Europe/Warsaw",
    locale: "pl",
    last_used_subscription: %{
      name: "Test",
      email: "test@example.org"
    }
  }

  describe "changeset/2" do
    test "create_user/1 with valid data creates a user, subscription, link" do
      assert {:ok, %User{} = user} = Users.create_user(@valid_attrs)
      assert user.email == "test@example.org"
      assert user.name == "Henryk Testowny"
      assert user.password == "secret123"
      assert user.locale == "pl"

      user =
        user |> DeerStorage.Repo.preload([:user_subscription_links, :available_subscriptions])

      assert user.available_subscriptions == [user.last_used_subscription]
    end

    test "create_user/1 without name returns error changeset" do
      changeset = User.changeset(%User{}, Map.delete(@valid_attrs, :name))
      refute changeset.valid?
    end

    test "create_user/1 with blank name returns error changeset" do
      changeset = User.changeset(%User{}, Map.put(@valid_attrs, :name, ""))
      refute changeset.valid?
    end

    test "create_user/1 with not supported locale returns invalid changeset" do
      changeset = User.changeset(%User{}, %{@valid_attrs | locale: "fr"})
      refute changeset.valid?
    end

    test "create_user/1 with invalid locale returns invalid changeset" do
      changeset = User.changeset(%User{}, %{@valid_attrs | locale: "DUPA"})
      refute changeset.valid?
    end

    test "create_user/1 fill-in default time zone in changeset if empty" do
      {:ok, user} =
        User.changeset(%User{}, %{@valid_attrs | time_zone: ""}) |> DeerStorage.Repo.insert()

      assert user.time_zone, "Europe/Warsaw"
    end

    test "create_user/1 with invalid time zone returns invalid changeset" do
      changeset = User.changeset(%User{}, %{@valid_attrs | time_zone: "DUPA"})
      refute changeset.valid?
    end

    test "create_user/1 with a role defined overwrites invalid field" do
      changeset = Map.merge(@valid_attrs, %{role: "admin"})

      {:ok, user} = User.changeset(%User{}, changeset) |> DeerStorage.Repo.insert()
      assert user.role, "user"
    end

    # Below is validates by Pow anyway, but let's be sure by writing simple tests

    test "create_user/1 without email returns error changeset" do
      changeset = User.changeset(%User{}, Map.delete(@valid_attrs, :email))
      refute changeset.valid?
    end

    test "email must contain at least an @" do
      attrs = %{@valid_attrs | email: "fooexample.com"}
      changeset = User.changeset(%User{}, attrs)
      assert %{email: ["has invalid format"]} = errors_on(changeset)
    end
  end
end
