defmodule DerbyLiveWeb.DataController do
  use DerbyLiveWeb, :controller

  alias DerbyLive.Importer
  alias DerbyLive.Racing.Event

  def import(conn, %{"event_key" => event_key} = params) do
    event = get_event_by_key(event_key)

    if event do
      import_racers(params, event)
      import_racer_heats(params, event)

      Phoenix.PubSub.broadcast(
        DerbyLive.PubSub,
        topic(event),
        {:sync_update, DateTime.utc_now()}
      )

      json(conn, %{status: "ok"})
    else
      json(conn, %{status: "error", message: "Invalid event key"})
    end
  end

  defp get_event_by_key(key) do
    Event
    |> Ash.Query.for_read(:by_key, %{key: key})
    |> Ash.read_one!()
  end

  defp import_racers(%{"racers" => racers}, event), do: Importer.import_racers(racers, event)

  defp import_racers(_params, _event), do: nil

  defp import_racer_heats(%{"racer_heats" => racer_heats}, event),
    do: Importer.import_racer_heats(racer_heats, event)

  defp import_racer_heats(_params, _event), do: nil

  defp topic(event), do: "sync_updates:#{event.key}"
end
