defmodule DerbyLive.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :name, :string
      add :url_prefix, :string
      add :status, :string

      timestamps()
    end
  end
end
