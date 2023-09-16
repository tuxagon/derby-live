defmodule DerbyLive.Email do
  use DerbyLiveWeb, :verified_routes

  require Phoenix.VerifiedRoutes
  import Swoosh.Email

  # TODO: Provide sender via config

  def login_link(user) do
    new()
    |> to(user)
    |> from({from_name(), from_email()})
    |> subject("Login to Derby Live")
    |> html_body(build_html(user))
    |> text_body(build_text(user))
  end

  defp build_html(user) do
    """
      <p>Click the link below to login to Derby Live.</p>

      <p><a href="#{login_link_url(user)}">Login</a></p>
    """
  end

  defp build_text(user) do
    """
      Click the link below to login to Derby Live.

      #{login_link_url(user)}
    """
  end

  defp login_link_url(%{auth_token: auth_token}), do: url(~p"/auth/verify/#{auth_token}/")

  defp from_name, do: "Derby Live"

  defp from_email, do: "noreply@example.com"
end
