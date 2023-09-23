defmodule DerbyLiveWeb.DataController do
  use DerbyLiveWeb, :controller

  alias DerbyLive.Importer
  alias DerbyLive.Racing

  def import(conn, %{"event_key" => event_key} = params) do
    event = Racing.get_event_by_key(event_key)

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
      json(conn, %{status: "errror", message: "Invalid event key"})
    end
  end

  defp import_racers(%{"racers" => racers}, event), do: Importer.import_racers(racers, event)

  defp import_racers(_params, _event), do: nil

  defp import_racer_heats(%{"racer_heats" => racer_heats}, event),
    do: Importer.import_racer_heats(racer_heats, event)

  defp import_racer_heats(_params, _event), do: nil

  defp topic(event), do: "sync_updates:#{event.key}"
end
