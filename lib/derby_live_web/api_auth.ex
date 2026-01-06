defmodule DerbyLiveWeb.ApiAuth do
  @moduledoc """
  API authentication using API keys.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias DerbyLive.Accounts.User

  def require_api_key(conn, _opts) do
    with {:ok, conn} <- fetch_api_key(conn) do
      conn
    else
      {:error, conn} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid API key"})
        |> halt()
    end
  end

  def fetch_api_key(conn) do
    case get_req_header(conn, "x-api-key") do
      [api_key] ->
        case User |> Ash.Query.for_read(:by_api_key, %{api_key: api_key}) |> Ash.read_one() do
          {:ok, user} when not is_nil(user) ->
            {:ok, assign(conn, :current_user, user)}

          _ ->
            {:error, conn}
        end

      [] ->
        {:error, conn}
    end
  end
end
