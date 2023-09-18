defmodule DerbyLiveWeb.DataController do
  use DerbyLiveWeb, :controller

  alias DerbyLive.Importer
  alias DerbyLive.Racing

  def import(conn, %{"event_key" => event_key} = params) do
    event = Racing.get_event_by_key(event_key)

    if event do
      import_racers(params, event)
      import_racer_heats(params, event)

      json(conn, %{status: "ok"})
    else
      json(conn, %{status: "errror", message: "Invalid event key"})
    end
  end

  def import_racers(%{"racers" => racers}, event), do: Importer.import_racers(racers, event)
  def import_racers(_params, _event), do: nil

  def import_racer_heats(%{"racer_heats" => racer_heats}, event),
    do: Importer.import_racer_heats(racer_heats, event)

  def import_racer_heats(_params, _event), do: nil
end
