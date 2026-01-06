defmodule DerbyLive.Accounts.Token do
  @moduledoc """
  Token resource for AshAuthentication.

  This resource stores authentication tokens used by AshAuthentication strategies,
  including magic link tokens. Tokens are automatically managed by the authentication
  system - created when magic links are requested and validated/consumed when users
  click the links.
  """
  use Ash.Resource,
    domain: DerbyLive.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  postgres do
    table("tokens")
    repo(DerbyLive.Repo)
  end

  actions do
    defaults([:read, :destroy])
  end
end
