defmodule DerbyLive.Account.UserNotifier do
  import Swoosh.Email

  alias DerbyLive.Mailer

  # TODO: Provide sender via config
  # TODO: Pull the link differently so that prod and dev are correct

  def deliver_login_link(user) do
    new()
    |> to(user)
    |> from({"Derby Live", "noreply@placeholder.com"})
    |> subject("Login to Derby Live")
    |> html_body(build_html(user))
    |> text_body(build_text(user))
    |> Mailer.deliver()
  end

  defp build_html(user) do
    """
      <p>
        Click the link below to login to Derby Live.
      </p>
      <p>
        <a href="http://localhost:4000/auth/#{user.auth_token}">
          Login
        </a>
      </p>
    """
  end

  defp build_text(user) do
    """
      Click the link below to login to Derby Live.

      http://localhost:4000/auth/#{user.auth_token}
    """
  end
end
