defmodule DerbyLiveWeb.HeatLive.Index do
  use DerbyLiveWeb, :live_view
  import DerbyLiveWeb.HeatComponent

  alias DerbyLive.Racing
  alias DerbyLive.Racing.Heat

  @car_colors ~w(e04242 e07a42 e0c242 e0e042 7ae042 42e042 42e07a 42e0c2 42e0e0 427ae0 4242e0 7a42e0 c242e0 e042e0 c2427a)

  @impl true
  @spec mount(map, any, map) :: {:ok, any}
  def mount(%{"event_key" => event_key}, _session, socket) do
    event = Racing.get_event_by_key(event_key)

    socket =
      socket
      |> assign(
        event: event,
        show_heat_selection: true,
        selected_heat: nil,
        current_heat: nil
      )
      |> fetch_and_assign_heats(event)

    Phoenix.PubSub.subscribe(DerbyLive.PubSub, "sync_updates:#{event.key}")

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_heat_selection", _params, socket) do
    {:noreply, assign(socket, show_heat_selection: !socket.assigns.show_heat_selection)}
  end

  def handle_event("select_heat", %{"heat-number" => heat_number}, socket) do
    heats = socket.assigns.heats
    current_heat = socket.assigns.current_heat

    selected_heat =
      Enum.find(heats, fn heat -> heat.heat_number == String.to_integer(heat_number) end)

    {:noreply,
     assign(socket,
       selected_heat: selected_heat,
       current_heat_changed:
         socket.assigns.current_heat_changed &&
           selected_heat.heat_number != current_heat.heat_number
     )}
  end

  def handle_event("select_current_heat", _params, socket) do
    current_heat = socket.assigns.current_heat
    {:noreply, assign(socket, selected_heat: current_heat, current_heat_changed: false)}
  end

  def handle_event("select_previous_heat", _params, socket) do
    heats = socket.assigns.heats
    current_heat = socket.assigns.current_heat

    selected_heat =
      Enum.find(heats, fn heat -> heat.heat_number == current_heat.heat_number - 1 end)

    {:noreply, assign(socket, selected_heat: selected_heat)}
  end

  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:sync_update, last_updated_at}, socket) do
    event = socket.assigns.event

    socket =
      socket
      |> assign(:last_updated_at, last_updated_at)
      |> fetch_and_assign_heats(event)

    {:noreply, socket}
  end

  defp fetch_and_assign_heats(socket, event) do
    heats =
      Racing.list_heats_for_event(event)
      |> Enum.map(fn heat ->
        heat
        |> Heat.sort_lanes_asc()
        |> heat_with_color_per_lane()
      end)

    existing_current_heat = socket.assigns.current_heat
    existing_selected_heat = socket.assigns.selected_heat

    {current_heat, next_heat, finished_heats, unfinished_heats} =
      split_heats_into_finished_and_unfinished(heats)

    selected_heat =
      if existing_selected_heat != nil && existing_current_heat != nil &&
           existing_current_heat.heat_number != existing_selected_heat.heat_number do
        Enum.find(heats, fn heat -> heat.heat_number == existing_selected_heat.heat_number end)
      else
        current_heat
      end

    assign(socket,
      heats: heats,
      selected_heat: selected_heat,
      current_heat: current_heat,
      current_heat_changed:
        existing_current_heat != nil &&
          existing_current_heat.heat_number != current_heat.heat_number,
      next_heat: next_heat,
      finished_heats: finished_heats,
      unfinished_heats: unfinished_heats |> Enum.drop(2),
      heats_count: length(heats)
    )
  end

  defp split_heats_into_finished_and_unfinished(heats) do
    {finished_heats, unfinished_heats} =
      Enum.split_with(heats, fn heat ->
        Enum.all?(heat.lanes, fn lane -> lane.racer_heat.finish_place != nil end)
      end)

    current_heat =
      case unfinished_heats do
        [] -> List.last(finished_heats)
        [heat | _] -> heat
      end

    next_heat =
      case unfinished_heats do
        [] -> nil
        [_ | []] -> nil
        [_ | [heat | _]] -> heat
      end

    {current_heat, next_heat, finished_heats, unfinished_heats}
  end

  defp heat_with_color_per_lane(heat) do
    colors =
      Enum.map(heat.lanes, fn lane ->
        car_number = lane.racer.car_number
        index = rem(car_number, length(@car_colors))
        Enum.at(@car_colors, index)
      end)

    Heat.add_color_to_each_lane(heat, colors)
  end
end
