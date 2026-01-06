defmodule DerbyLive.Repo.Migrations.RemoveLegacyAuthFields do
  @moduledoc """
  Removes legacy authentication fields from the users table.

  These fields were used before migrating to AshAuthentication:
  - auth_token: stored the login token
  - auth_token_expires_at: token expiration timestamp

  Now authentication is handled via JWT tokens stored in the tokens table.
  """
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :auth_token, :string
      remove :auth_token_expires_at, :naive_datetime
    end
  end
end
