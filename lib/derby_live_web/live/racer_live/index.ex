defmodule DerbyLiveWeb.RacerLive.Index do
  use DerbyLiveWeb, :live_view

  alias DerbyLive.Racing

  @impl true
  def mount(%{"event_key" => event_key}, _session, socket) do
    event = Racing.get_event_by_key(event_key)

    racers = Racing.list_racers_by_event(event)

    {:ok, stream(socket, :racers, racers)}
  end
end
