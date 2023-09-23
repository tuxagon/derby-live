defmodule DerbyLiveWeb.HeatLive.Index do
  use DerbyLiveWeb, :live_view

  alias DerbyLive.Racing

  @impl true
  def mount(%{"event_key" => event_key}, _session, socket) do
    event = Racing.get_event_by_key(event_key)

    heats = Racing.list_heats_for_event(event)

    socket =
      socket
      |> assign(:event, event)
      |> stream_configure(:heats,
        dom_id: fn heat ->
          IO.inspect(heat)
          "heat-#{heat.heat_number}"
        end
      )
      |> stream(:heats, heats)

    {:ok, socket}
  end
end
