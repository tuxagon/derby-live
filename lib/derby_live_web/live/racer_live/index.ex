defmodule DerbyLiveWeb.RacerLive.Index do
  use DerbyLiveWeb, :live_view

  alias DerbyLive.Racing.Event
  alias DerbyLive.Racing.Racer

  @impl true
  def mount(%{"event_key" => event_key}, _session, socket) do
    event = get_event_by_key(event_key)

    racers =
      if event do
        list_racers_for_event(event.id)
      else
        []
      end

    {:ok, stream(socket, :racers, racers)}
  end

  defp get_event_by_key(key) do
    Event
    |> Ash.Query.for_read(:by_key, %{key: key})
    |> Ash.read_one!()
  end

  defp list_racers_for_event(event_id) do
    Racer
    |> Ash.Query.for_read(:for_event, %{event_id: event_id})
    |> Ash.read!()
  end
end
