defmodule DerbyLiveWeb.AuthControllerTest do
  use DerbyLiveWeb.ConnCase
  import Swoosh.TestAssertions

  describe "sign-in page" do
    test "shows magic link form", %{conn: conn} do
      conn = get(conn, ~p"/sign-in")
      # AshAuthentication's sign-in page shows the configured strategy
      assert html_response(conn, 200) =~ "magic link"
    end
  end

  describe "sign-out" do
    test "clears session and redirects", %{conn: conn} do
      user = insert_user()
      conn = log_in_user(conn, user)

      # AshAuthentication sign_out_route creates a GET route at /sign-out
      conn = get(conn, ~p"/sign-out")
      assert redirected_to(conn) =~ "/sign-in"
    end
  end

  describe "magic link request" do
    test "sends email for existing user", %{conn: conn} do
      user = insert_user()

      conn =
        post(conn, ~p"/auth/user/magic_link/request", %{
          "user" => %{"email" => user.email}
        })

      # Should redirect back with success message
      assert redirected_to(conn)

      # Email should be sent
      assert_email_sent(
        subject: "Login to Derby Live",
        to: user.email
      )
    end

    test "handles non-existing email gracefully", %{conn: conn} do
      conn =
        post(conn, ~p"/auth/user/magic_link/request", %{
          "user" => %{"email" => "nonexistent@example.com"}
        })

      # Should still redirect (don't reveal if email exists)
      assert redirected_to(conn)
    end
  end
end
