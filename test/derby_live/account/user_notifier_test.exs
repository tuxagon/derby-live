defmodule DerbyLive.Account.UserNotifierTest do
  use ExUnit.Case, async: true
  import Swoosh.TestAssertions
  import DerbyLive.Factory

  alias DerbyLive.Account.UserNotifier

  test "deliver_login_link/1" do
    user = build(:user)

    UserNotifier.deliver_login_link(user)

    assert_email_sent(
      subject: "Login to Derby Live",
      to: user.email,
      text_body: ~r/#{user.auth_token}/
    )
  end
end
