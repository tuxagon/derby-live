defmodule DerbyLive.Repo.Migrations.CreateRacers do
  use Ecto.Migration

  def change do
    create table(:racers) do
      add :racer_id, :integer
      add :first_name, :string
      add :last_name, :string
      add :rank, :string
      add :group, :string
      add :car_name, :string
      add :car_number, :integer

      timestamps()
    end
  end
end
