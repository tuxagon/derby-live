defmodule DerbyLive.Racing do
  import Ecto.Query

  alias DerbyLive.Repo
  alias DerbyLive.Racing.Heat
  alias DerbyLive.Racing.Lane
  alias DerbyLive.Racing.Racer

  def list_racers() do
    Repo.all(Racer)
  end

  def list_racers_by_event(event) do
    from(r in Racer,
      where: r.event_id == ^event.id,
      order_by: [asc: r.group, asc: r.car_number],
      select: r
    )
    |> Repo.all()
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

  def list_racer_heats_by_event(event) do
    from(rh in RacerHeat,
      where: rh.event_id == ^event.id,
      order_by: [asc: rh.heat_number, asc: rh.lane_number],
      select: rh
    )
    |> Repo.all()
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

  def list_heats_for_event(event) do
    from(rh in RacerHeat,
      join: r in Racer,
      on: rh.racer_id == r.racer_id,
      where: rh.event_id == ^event.id,
      order_by: [asc: rh.heat_number],
      select: {r, rh}
    )
    |> Repo.all()
    |> Enum.group_by(fn {_r, rh} -> rh.heat_number end)
    |> Enum.map(fn {heat_number, lanes} ->
      %Heat{
        heat_number: heat_number,
        lanes: Enum.map(lanes, fn {r, rh} -> %Lane{racer: r, racer_heat: rh} end)
      }
    end)
  end

  alias DerbyLive.Racing.Event

  def list_events do
    Repo.all(Event)
  end

  def list_my_events(user) do
    from(e in Event,
      where: e.user_id == ^user.id,
      order_by: [asc: e.name],
      select: e
    )
    |> Repo.all()
  end

  def get_event!(id), do: Repo.get!(Event, id)

  def get_event_by_key(key) do
    Repo.get_by(Event, key: key)
  end

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_event(%Event{} = event, attrs) do
    event
    |> Event.update_changeset(attrs)
    |> Repo.update()
  end

  def archive_event(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: "archived"})
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
