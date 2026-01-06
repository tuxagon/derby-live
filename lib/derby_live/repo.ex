defmodule DerbyLive.Repo do
  use AshPostgres.Repo, otp_app: :derby_live

  def installed_extensions do
    # See priv/repo/migrations/20251231190512_create_ash_tables_extensions_1.exs
    ["ash-functions", "citext"]
  end

  def min_pg_version do
    %Version{major: 17, minor: 0, patch: 0}
  end
end
