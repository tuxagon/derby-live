defmodule DerbyLive.Repo.Migrations.AddEventReferencesToRacersAndRacerHeats do
  use Ecto.Migration

  def change do
    alter table(:racers) do
      add :event_id, references(:events, on_delete: :nothing)
    end

    alter table(:racer_heats) do
      add :event_id, references(:events, on_delete: :nothing)
    end
  end
end
