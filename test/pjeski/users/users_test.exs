defmodule Pjeski.UsersTest do
  use Pjeski.DataCase

  alias Pjeski.Users
  alias Pjeski.Users.User

  @valid_attrs %{
    email: "test@example.org",
    name: "Henryk Testowny",
    password: "secret123",
    password_confirmation: "secret123",
    time_zone: "Europe/Warsaw",
    locale: "pl",
    subscription: %{
      name: "Test",
      email: "test@example.org"
    }
  }

  describe "changeset/2" do
    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Users.create_user(@valid_attrs)
      assert user.email == "test@example.org"
      assert user.name == "Henryk Testowny"
      assert user.password == "secret123"
      assert user.locale == "pl"
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
      {:ok, user} = User.changeset(%User{}, %{@valid_attrs | time_zone: ""}) |> Pjeski.Repo.insert
      assert user.time_zone, "Europe/Warsaw"
    end

    test "create_user/1 with invalid time zone returns invalid changeset" do
      changeset = User.changeset(%User{}, %{@valid_attrs | time_zone: "DUPA"})
      refute changeset.valid?
    end

    test "create_user/1 with a role defined overwrites invalid field" do
      changeset = Map.merge(@valid_attrs, %{role: "admin"})

      {:ok, user} = User.changeset(%User{}, changeset) |> Pjeski.Repo.insert
      assert user.role, "user"
    end

    test "changeset is invalid if subscription email is used already" do
      %User{} |> User.changeset(@valid_attrs) |> Pjeski.Repo.insert!

      assert {:error, changeset} = User.changeset(%User{}, %{@valid_attrs | email: "valid_new_user_email@example.org"}) |> Repo.insert
      assert { "has already been taken", _ } = changeset.changes.subscription.errors[:email]
    end

    # Below is validates by Pow anyway, but let's be sure by writing simple tests

    test "changeset is invalid if user email is used already" do
      %User{} |> User.changeset(@valid_attrs) |> Pjeski.Repo.insert!

      user2 = User.changeset(
        %User{},
        %{@valid_attrs | subscription: %{@valid_attrs | email: "valid_new_subscription_email@example.org"}}
      )

      assert {:error, changeset} = Repo.insert(user2)

      assert { "has already been taken", _ } = changeset.errors[:email]
    end

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
