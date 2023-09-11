defmodule DerbyLive.Repo do
  use Ecto.Repo,
    otp_app: :derby_live,
    adapter: Ecto.Adapters.Postgres
end
