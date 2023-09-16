defmodule DerbyLiveWeb.ApiAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias DerbyLive.Account

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
        if user = Account.get_user_by_api_key(api_key) do
          {:ok, assign(conn, :current_user, user)}
        else
          {:error, conn}
        end

      [] ->
        {:error, conn}
    end
  end
end
