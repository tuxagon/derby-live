defmodule Mix.Tasks.DerbyLive.CreateUser do
  @moduledoc """
  Creates a new user in the system.

  ## Usage

      mix derby_live.create_user "John Doe" "john@example.com"

  ## Arguments

    * `name` - The user's display name
    * `email` - The user's email address (must be unique)

  ## Examples

      $ mix derby_live.create_user "Pack Master" "admin@pack102.org"
      Created user Pack Master (admin@pack102.org)
      API Key: abc123...

  The API key is automatically generated and displayed on success.
  Users can then request a magic link at /sign-in to log in.
  """
  use Mix.Task

  alias DerbyLive.Accounts.User

  @shortdoc "Creates a new user"

  @impl Mix.Task
  def run(args) do
    case args do
      [name, email] ->
        Mix.Task.run("app.start")
        create_user(name, email)

      _ ->
        Mix.shell().error("Usage: mix derby_live.create_user <name> <email>")
        Mix.shell().error("Example: mix derby_live.create_user \"John Doe\" \"john@example.com\"")
    end
  end

  defp create_user(name, email) do
    case Ash.create(User, %{name: name, email: email}, action: :register) do
      {:ok, user} ->
        Mix.shell().info("Created user #{user.name} (#{user.email})")
        Mix.shell().info("API Key: #{user.api_key}")

      {:error, error} ->
        Mix.shell().error("Error: #{Exception.message(error)}")
    end
  end
end
