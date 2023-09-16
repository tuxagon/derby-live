defmodule DerbyLiveWeb.AuthController do
  use DerbyLiveWeb, :controller

  alias DerbyLive.Account
  alias DerbyLiveWeb.UserAuth

  def index(conn, _params) do
    conn = assign(conn, :form, %{"email" => ""})
    render(conn, "index.html")
  end

  def login(conn, %{"email" => email}) do
    case Account.get_user_by_email(email) do
      %Account.User{} = user ->
        Account.send_login_link_email(user)

        conn
        |> put_flash(:info, "Check your email for a login link")
        |> redirect(to: ~p"/auth")

      nil ->
        conn
        |> put_flash(:info, "Check your email for a login link")
        |> redirect(to: ~p"/auth")
    end
  end

  def logout(conn, _params) do
    conn
    |> UserAuth.log_out_user()
  end

  def verify(conn, %{"token" => token}) do
    case Account.get_user_by_auth_token(token) do
      %Account.User{} = user ->
        conn
        |> UserAuth.log_in_user(user)

      nil ->
        conn
        |> put_flash(:error, "Invalid token")
        |> redirect(to: "/auth")
    end
  end
end
