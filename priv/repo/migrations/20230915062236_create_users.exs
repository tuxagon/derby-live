defmodule DerbyLive.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      add :auth_token, :string
      add :auth_token_expires_at, :naive_datetime

      timestamps()
    end
  end
end
