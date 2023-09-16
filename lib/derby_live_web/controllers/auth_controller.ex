defmodule DerbyLiveWeb.AuthController do
  use DerbyLiveWeb, :controller

  alias DerbyLive.Account

  def index(conn, _params) do
    conn = assign(conn, :form, %{"email" => ""})
    render(conn, "index.html")
  end

  def login(conn, %{"email" => email}) do
    case Account.get_user_by_email(email) do
      %Account.User{} = user ->
        Account.send_login_link_email(user)

        conn
        |> put_flash(:success, "Check your email for a login link")
        |> redirect(to: ~p"/auth")

      nil ->
        conn
        |> put_flash(:success, "Check your email for a login link")
        |> redirect(to: ~p"/auth")
    end
  end

  def verify(conn, %{"token" => token}) do
    case Account.get_user_by_auth_token(token) do
      %Account.User{} = user ->
        conn
        |> put_session(:current_user_id, user.id)
        |> redirect(to: "/")

      nil ->
        conn
        |> put_flash(:error, "Invalid token")
        |> redirect(to: "/auth")
    end
  end
end
