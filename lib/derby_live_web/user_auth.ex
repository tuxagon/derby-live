defmodule DerbyLiveWeb.UserAuth do
  @moduledoc """
  User authentication helpers for Phoenix controllers and LiveViews.

  Works with AshAuthentication to manage user sessions and access control.
  """
  use DerbyLiveWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  @doc """
  Logs out the user by clearing the session.
  """
  def log_out_user(conn) do
    if live_socket_id = get_session(conn, :live_socket_id) do
      DerbyLiveWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> redirect(to: ~p"/sign-in")
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_session(:return_to, current_path(conn))
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: ~p"/sign-in")
      |> halt()
    end
  end

  @doc """
  LiveView on_mount callback to mount current user.
  """
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
        |> Phoenix.LiveView.redirect(to: ~p"/sign-in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      # Try to load user from token first (our custom flow)
      # Then fall back to AshAuthentication's subject-based flow
      cond do
        token = session["user_token"] ->
          case AshAuthentication.Jwt.verify(token, :derby_live) do
            {:ok, user, _claims} -> user
            _ -> nil
          end

        subject = session["user"] ->
          case AshAuthentication.subject_to_user(subject, DerbyLive.Accounts.User) do
            {:ok, user} -> user
            _ -> nil
          end

        true ->
          nil
      end
    end)
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> Plug.Conn.clear_session()
  end

  defp signed_in_path(_conn), do: ~p"/events"
end
