defmodule DerbyLiveWeb.AuthController do
  @moduledoc """
  Authentication controller for AshAuthentication.

  This controller handles authentication callbacks from AshAuthentication,
  including magic link sign-ins and sign-outs.
  """
  use DerbyLiveWeb, :controller
  use AshAuthentication.Phoenix.Controller

  @doc """
  Called when a user successfully authenticates.
  """
  def success(conn, {:password, :sign_in}, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/events"

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    |> assign(:current_user, user)
    |> put_flash(:info, "Welcome back!")
    |> redirect(to: return_to)
  end

  def success(conn, {:magic_link, :sign_in}, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/events"

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    |> assign(:current_user, user)
    |> put_flash(:info, "Welcome back!")
    |> redirect(to: return_to)
  end

  def success(conn, {:magic_link, :request}, _user_or_email, _token) do
    conn
    |> put_flash(:info, "Check your email for a login link")
    |> redirect(to: ~p"/sign-in")
  end

  def success(conn, _activity, _user, _token) do
    conn
    |> put_flash(:info, "Success!")
    |> redirect(to: ~p"/events")
  end

  @doc """
  Called when authentication fails.
  """
  def failure(conn, {:magic_link, :sign_in}, _reason) do
    conn
    |> put_flash(:error, "Magic link is invalid or has expired")
    |> redirect(to: ~p"/sign-in")
  end

  def failure(conn, {:magic_link, :request}, _reason) do
    # Don't reveal whether the email exists or not
    conn
    |> put_flash(:info, "If that email exists, we've sent a login link")
    |> redirect(to: ~p"/sign-in")
  end

  def failure(conn, _activity, _reason) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: ~p"/sign-in")
  end

  @doc """
  Signs out the user.
  """
  def sign_out(conn, _params) do
    return_to = get_session(conn, :return_to) || ~p"/sign-in"

    conn
    |> clear_session(:derby_live)
    |> put_flash(:info, "You have been signed out")
    |> redirect(to: return_to)
  end

  @doc """
  Callback from LiveView magic link sign-in.
  Stores the token in the session and redirects.
  """
  def callback(conn, %{"token" => token}) do
    return_to = get_session(conn, :return_to) || ~p"/events"

    conn
    |> delete_session(:return_to)
    |> put_session(:user_token, token)
    |> configure_session(renew: true)
    |> put_flash(:info, "Welcome back!")
    |> redirect(to: return_to)
  end
end
