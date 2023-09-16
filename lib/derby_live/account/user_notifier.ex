defmodule DerbyLive.Account.UserNotifier do
  alias DerbyLive.Email
  alias DerbyLive.Mailer

  def deliver_login_link(user) do
    Email.login_link(user)
    |> Mailer.deliver()
  end
end
