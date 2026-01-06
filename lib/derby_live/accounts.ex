defmodule DerbyLive.Accounts do
  @moduledoc """
  The Accounts domain handles user authentication and account management.

  This domain uses Ash Framework with AshAuthentication for magic link authentication.
  """
  use Ash.Domain

  resources do
    resource(DerbyLive.Accounts.User)
    resource(DerbyLive.Accounts.Token)
  end
end
