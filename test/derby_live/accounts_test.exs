defmodule DerbyLive.AccountsTest do
  use DerbyLive.DataCase, async: true

  import DerbyLive.Factory

  require Ash.Query

  alias DerbyLive.Accounts.User

  describe "User resource" do
    test "register action creates a user with api_key" do
      attrs = build_user()

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create()

      assert user.name == attrs.name
      assert user.email == attrs.email
      assert is_binary(user.api_key)
      assert String.length(user.api_key) == 64
    end

    test "by_email action finds user by email" do
      user = insert_user()

      found =
        User
        |> Ash.Query.for_read(:by_email, %{email: user.email})
        |> Ash.read_one!()

      assert found.id == user.id
    end

    test "by_email action returns nil for non-existent email" do
      result =
        User
        |> Ash.Query.for_read(:by_email, %{email: "fake@example.com"})
        |> Ash.read_one!()

      assert is_nil(result)
    end

    test "by_api_key action finds user by api_key" do
      user = insert_user()

      found =
        User
        |> Ash.Query.for_read(:by_api_key, %{api_key: user.api_key})
        |> Ash.read_one!()

      assert found.id == user.id
    end

    test "by_api_key action returns nil for non-existent api_key" do
      result =
        User
        |> Ash.Query.for_read(:by_api_key, %{api_key: "fake-api-key"})
        |> Ash.read_one!()

      assert is_nil(result)
    end

    test "destroy action deletes user" do
      user = insert_user()
      :ok = Ash.destroy!(user)

      assert_raise Ash.Error.Invalid, fn ->
        Ash.get!(User, user.id)
      end
    end

    test "update action updates user" do
      user = insert_user()

      {:ok, updated} =
        user
        |> Ash.Changeset.for_update(:update, %{name: "New Name"})
        |> Ash.update()

      assert updated.name == "New Name"
      assert updated.email == user.email
    end
  end
end
