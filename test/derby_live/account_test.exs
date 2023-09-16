defmodule DerbyLive.AccountTest do
  use DerbyLive.DataCase, async: true

  alias DerbyLive.Account.User

  defp fifteen_minutes_in_the_future?(datetime) do
    nowish =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)

    nowish < datetime && datetime < NaiveDateTime.add(nowish, 60 * 16)
  end

  describe "get_user!/1" do
    test "returns user if it exists" do
      user = insert(:user)
      assert DerbyLive.Account.get_user!(user.id) == user
    end

    test "raises if user does not exist" do
      assert_raise Ecto.NoResultsError, fn -> DerbyLive.Account.get_user!(0) end
    end
  end

  describe "get_user_by_id/1" do
    test "returns user if it exists" do
      user = insert(:user)
      assert DerbyLive.Account.get_user_by_id(user.id) == user
    end

    test "returns nil if user does not exist" do
      refute DerbyLive.Account.get_user_by_id(0)
    end
  end

  describe "get_user_by_email/1" do
    test "returns user with matching email" do
      user = insert(:user)
      assert DerbyLive.Account.get_user_by_email(user.email) == user
    end

    test "returns nil if no user has matching email" do
      refute DerbyLive.Account.get_user_by_email("fake@example.com")
    end
  end

  describe "get_user_by_auth_token/1" do
    test "returns user with matching auth token" do
      user = insert(:user)
      assert DerbyLive.Account.get_user_by_auth_token(user.auth_token) == user
    end

    test "returns nil if no user has matching auth token" do
      refute DerbyLive.Account.get_user_by_auth_token("fake-auth-token")
    end
  end

  test "register_user/1 registers user" do
    attrs = params_for(:user)
    {:ok, user} = DerbyLive.Account.register_user(attrs)
    assert user.name == attrs[:name]
    assert user.email == attrs[:email]
    assert String.length(user.auth_token) == 64
    assert fifteen_minutes_in_the_future?(user.auth_token_expires_at)
  end

  test "delete_user/1 deletes user" do
    user = insert(:user)
    assert {:ok, %User{}} = DerbyLive.Account.delete_user(user)
    assert_raise Ecto.NoResultsError, fn -> DerbyLive.Account.get_user!(user.id) end
  end

  test "reset_auth_token/1 resets auth token" do
    user = insert(:user)
    original_auth_token = user.auth_token
    assert {:ok, user} = DerbyLive.Account.reset_auth_token(user)
    assert String.length(user.auth_token) == 64
    refute user.auth_token == original_auth_token
    assert fifteen_minutes_in_the_future?(user.auth_token_expires_at)
  end
end
