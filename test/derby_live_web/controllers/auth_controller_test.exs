defmodule DerbyLiveWeb.AuthControllerTest do
  use DerbyLiveWeb.ConnCase
  import Swoosh.TestAssertions

  describe "index" do
    test "shows email input for sending login link", %{conn: conn} do
      conn = get(conn, ~p"/auth")
      assert html_response(conn, 200) =~ "Send login link"
    end
  end

  describe "login" do
    test "sends email link for existing user", %{conn: conn} do
      user = insert(:user)
      conn = post(conn, ~p"/auth/login", %{email: user.email})
      assert "/auth" = redirected_to(conn)
      assert %{"info" => "Check your email for a login link"} = conn.assigns.flash

      assert_email_sent(
        subject: "Login to Derby Live",
        to: {user.name, user.email},
        text_body: ~r/auth\/verify\/#{user.auth_token}/
      )
    end

    test "does not send email link for non-existing user", %{conn: conn} do
      conn = post(conn, ~p"/auth/login", %{email: "fake@example.com"})
      assert "/auth" = redirected_to(conn)
      assert %{"info" => "Check your email for a login link"} = conn.assigns.flash

      assert_no_email_sent()
    end
  end

  describe "logout" do
    test "logout", %{conn: conn} do
      conn = delete(conn, ~p"/auth/logout")
      assert "/auth" = redirected_to(conn)
      refute get_session(conn, :current_user_id)
    end
  end

  describe "verify" do
    test "redirects to root for valid token", %{conn: conn} do
      user = insert(:user)
      conn = get(conn, ~p"/auth/verify/#{user.auth_token}")
      assert "/events" = redirected_to(conn)
      assert user.id == get_session(conn, :current_user_id)
    end

    test "redirects to auth for invalid token", %{conn: conn} do
      conn = get(conn, ~p"/auth/verify/invalid-token")
      assert "/auth" = redirected_to(conn)
      assert %{"error" => "Invalid token"} = conn.assigns.flash
    end
  end
end
