defmodule DerbyLiveWeb.HeatLive.Index do
  use DerbyLiveWeb, :live_view

  alias DerbyLive.Racing

  @impl true
  def mount(%{"event_key" => event_key}, _session, socket) do
    event = Racing.get_event_by_key(event_key)

    heats = Racing.list_heats_for_event(event)

    Phoenix.PubSub.subscribe(DerbyLive.PubSub, "sync_updates:#{event.key}")

    socket =
      socket
      |> assign(:event, event)
      |> assign(:heats, heats)

    {:ok, socket}
  end

  @impl true
  def handle_info({:sync_update, last_updated_at}, socket) do
    event = socket.assigns.event

    heats = Racing.list_heats_for_event(event)

    socket =
      socket
      |> assign(heats: heats, last_updated_at: last_updated_at)

    {:noreply, socket}
  end
end
