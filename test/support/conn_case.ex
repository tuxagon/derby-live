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

  @doc """
  Setup helper that registers and logs in celebs.

      setup :register_and_log_in_celeb

  It stores an updated connection and a registered celeb in the
  test context.
  """
  def register_and_log_in_celeb(%{conn: conn}) do
    celeb = DerbyLive.VipFixtures.celeb_fixture()
    %{conn: log_in_celeb(conn, celeb), celeb: celeb}
  end

  @doc """
  Logs the given `celeb` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_celeb(conn, celeb) do
    token = DerbyLive.Vip.generate_celeb_session_token(celeb)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:celeb_token, token)
  end
end
