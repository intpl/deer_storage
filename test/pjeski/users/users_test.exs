defmodule Pjeski.UsersTest do
  use Pjeski.DataCase

  alias Pjeski.Users

  describe "users" do
    alias Pjeski.Users.User

    @valid_attrs %{email: "some bio", email: "test@example.org", name: "Henryk Testowny", password: "secret123", confirm_password: "secret123", locale: "pl"}

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Users.create_user(@valid_attrs)
      assert user.email == "test@example.org"
      assert user.name == "Henryk Testowny"
      assert user.password == "secret123"
      assert user.locale == :pl
    end

    test "create_user/1 without email returns error changeset" do
      changeset = User.changeset(%User{}, Map.delete(@valid_attrs, :email))
      refute changeset.valid?
    end

    test "create_user/1 without name returns error changeset" do
      changeset = User.changeset(%User{}, Map.delete(@valid_attrs, :name))
      refute changeset.valid?
    end

    test "create_user/1 with blank name returns error changeset" do
      changeset = User.changeset(%User{}, Map.put(@valid_attrs, :name, ""))
      refute changeset.valid?
    end

    test "create_user/1 without locale (optional) returns valid changeset" do
      changeset = User.changeset(%User{}, Map.delete(@valid_attrs, :locale))
      assert changeset.valid?
    end

    test "create_user/1 with not supported locale returns invalid changeset" do
      changeset = User.changeset(%User{}, %{@valid_attrs | locale: "fr"})
      refute changeset.valid?
    end

    test "create_user/1 with invalid locale returns invalid changeset" do
      changeset = User.changeset(%User{}, %{@valid_attrs | locale: "DUPA"})
      refute changeset.valid?
    end

    # Below is validates by Pow anyway, but let's be sure by writing simple tests

    test "changeset is invalid if email is used already" do
      %User{} |> User.changeset(@valid_attrs) |> Pjeski.Repo.insert!
      user2 = %User{} |> User.changeset(@valid_attrs |> Map.put(:name, "test2"))

      assert {:error, changeset} = Repo.insert(user2)
      assert { "has already been taken", _ } = changeset.errors[:email]
    end

    test "email must contain at least an @" do
      attrs = %{@valid_attrs | email: "fooexample.com"}
      changeset = User.changeset(%User{}, attrs)
      assert %{email: ["has invalid format"]} = errors_on(changeset)
    end
  end
end
