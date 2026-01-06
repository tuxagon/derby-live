defmodule Mix.Tasks.DerbyLive.CreateUserTest do
  use DerbyLive.DataCase, async: true

  import ExUnit.CaptureIO

  alias Mix.Tasks.DerbyLive.CreateUser
  alias DerbyLive.Accounts.User

  describe "run/1" do
    test "creates a user with valid arguments" do
      output =
        capture_io(fn ->
          CreateUser.run(["Test User", "test@example.com"])
        end)

      assert output =~ "Created user Test User (test@example.com)"
      assert output =~ "API Key:"

      # Verify user was created in database
      user =
        User
        |> Ash.Query.for_read(:by_email, %{email: "test@example.com"})
        |> Ash.read_one!()

      assert user.name == "Test User"
      assert user.email == "test@example.com"
      assert is_binary(user.api_key)
      assert String.length(user.api_key) == 64
    end

    test "shows error for duplicate email" do
      # Create first user
      Ash.create!(User, %{name: "First User", email: "duplicate@example.com"}, action: :register)

      # Try to create second user with same email - error goes to stderr
      output =
        capture_io(:stderr, fn ->
          CreateUser.run(["Second User", "duplicate@example.com"])
        end)

      assert output =~ "Error:"
    end

    test "shows usage when no arguments provided" do
      # Usage errors go to stderr
      output =
        capture_io(:stderr, fn ->
          CreateUser.run([])
        end)

      assert output =~ "Usage: mix derby_live.create_user <name> <email>"
    end

    test "shows usage when only one argument provided" do
      output =
        capture_io(:stderr, fn ->
          CreateUser.run(["Only Name"])
        end)

      assert output =~ "Usage: mix derby_live.create_user <name> <email>"
    end

    test "shows usage when too many arguments provided" do
      output =
        capture_io(:stderr, fn ->
          CreateUser.run(["Name", "email@example.com", "extra"])
        end)

      assert output =~ "Usage: mix derby_live.create_user <name> <email>"
    end
  end
end
