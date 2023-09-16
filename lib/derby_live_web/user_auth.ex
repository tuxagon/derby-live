defmodule DerbyLiveWeb.UserAuth do
  use DerbyLiveWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias DerbyLive.Account

  def log_in_user(conn, user, _params \\ %{}) do
    conn
    |> renew_session()
    |> put_session(:current_user_id, user.id)
    |> redirect(to: signed_in_path(conn))
  end

  def log_out_user(conn) do
    if live_socket_id = get_session(conn, :live_socket_id) do
      DerbyLiveWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> redirect(to: ~p"/auth")
  end

  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :current_user_id)
    user = user_id && Account.get_user_by_id(user_id)
    assign(conn, :current_user, user)
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: ~p"/auth")
      |> halt()
    end
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/auth")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_celeb_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_id = session["current_user_id"] do
        Account.get_user_by_id(user_id)
      end
    end)
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp signed_in_path(_conn), do: ~p"/events"
end
