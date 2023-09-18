defmodule DerbyLive.Racing do
  import Ecto.Query

  alias DerbyLive.Repo
  alias DerbyLive.Racing.Racer

  def list_racers do
    Repo.all(Racer)
  end

  def get_racer!(id) do
    Repo.get!(Racer, id)
  end

  def create_racer(attrs \\ %{}) do
    %Racer{}
    |> Racer.changeset(attrs)
    |> Repo.insert()
  end

  def update_racer(racer, attrs) do
    racer
    |> Racer.changeset(attrs)
    |> Repo.update()
  end

  def delete_racer(racer) do
    Repo.delete(racer)
  end

  alias DerbyLive.Racing.RacerHeat

  def list_racer_heats do
    Repo.all(RacerHeat)
  end

  def get_racer_heat!(id) do
    Repo.get!(RacerHeat, id)
  end

  def create_racer_heat(attrs \\ %{}) do
    %RacerHeat{}
    |> RacerHeat.changeset(attrs)
    |> Repo.insert()
  end

  def update_racer_heat(racer_heat, attrs) do
    racer_heat
    |> RacerHeat.changeset(attrs)
    |> Repo.update()
  end

  def delete_racer_heat(racer_heat) do
    Repo.delete(racer_heat)
  end

  def list_heats do
    from(rh in RacerHeat,
      join: r in Racer,
      on: rh.racer_id == r.racer_id,
      order_by: [asc: rh.heat_number],
      select: {r, rh}
    )
    |> Repo.all()
    |> Enum.group_by(fn {_r, rh} -> rh.heat_number end)
  end

  alias DerbyLive.Racing.Event

  def list_events do
    Repo.all(Event)
  end

  def get_event!(id), do: Repo.get!(Event, id)

  def get_event_by_key(key) do
    Repo.get_by(Event, key: key)
  end

  def create_live_event(attrs \\ %{}) do
    %Event{}
    |> Event.live_changeset(attrs)
    |> Repo.insert()
  end

  def update_event(%Event{} = event, attrs) do
    event
    |> Event.update_changeset(attrs)
    |> Repo.update()
  end

  def archive_event(%Event{} = event) do
    event
    |> Event.archived_changeset()
    |> Repo.update()
  end

  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  def change_event(%Event{} = event, attrs \\ %{}) do
    event
    |> Event.update_changeset(attrs)
  end
end
