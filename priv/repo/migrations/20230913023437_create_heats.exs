defmodule DerbyLive.Repo.Migrations.CreateHeats do
  use Ecto.Migration

  def change do
    create table(:heats) do
      add :racer_id, :integer
      add :group, :string
      add :rank, :string
      add :heat_number, :integer
      add :lane_number, :integer
      add :car_number, :integer
      add :finish_seconds, :float
      add :finish_place, :integer
      add :finished_at, :utc_datetime

      timestamps()
    end
  end
end
