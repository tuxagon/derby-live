defmodule DerbyLiveWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use DerbyLiveWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint DerbyLiveWeb.Endpoint

      use DerbyLiveWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import DerbyLiveWeb.ConnCase
      import DerbyLive.Factory
    end
  end

  setup tags do
    DerbyLive.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def register_and_log_in_user(%{conn: conn}) do
    user = DerbyLive.Factory.insert_user()
    %{conn: log_in_user(conn, user), user: user}
  end

  def log_in_user(conn, user) do
    # Generate a token for the user so we can store in session
    # AshAuthentication expects users to have a token attached
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)

    # Store the token in the tokens table (required when require_token_presence_for_authentication? is true)
    DerbyLive.Accounts.Token
    |> Ash.Changeset.for_create(:store_token, %{
      token: token,
      purpose: "user"
    })
    |> Ash.create!()

    user_with_token = Ash.Resource.put_metadata(user, :token, token)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> AshAuthentication.Plug.Helpers.store_in_session(user_with_token)
  end
end
