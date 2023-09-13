defmodule DerbyLive.Repo.Migrations.CreateRacerHeats do
  use Ecto.Migration

  def change do
    create table(:racer_heats) do
      add :racer_id, :integer
      add :group, :string
      add :heat_number, :integer
      add :lane_number, :integer
      add :car_number, :integer
      add :finish_seconds, :float
      add :finish_place, :integer
      add :finished_at, :naive_datetime

      timestamps()
    end
  end
end
