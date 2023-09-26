defmodule DerbyLiveWeb.HeatLive.Index do
  use DerbyLiveWeb, :live_view
  import DerbyLiveWeb.HeatComponent

  alias DerbyLive.Racing
  alias DerbyLive.Racing.Heat

  @gray_color "aaaaaa"
  @car_colors ~w(40a4d8 33beb7 b2c444 fecc2f f8a227 f66220 dc3839 ee6579 a3644d9")

  @impl true
  @spec mount(map, any, map) :: {:ok, any}
  def mount(%{"event_key" => event_key}, _session, socket) do
    event = Racing.get_event_by_key(event_key)

    socket =
      socket
      |> assign(:event, event)
      |> fetch_and_assign_heats(event)

    Phoenix.PubSub.subscribe(DerbyLive.PubSub, "sync_updates:#{event.key}")

    {:ok, socket}
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
        |> heat_with_gray_color_per_lane()
      end)

    {current_heat, next_heat, finished_heats, unfinished_heats} =
      split_heats_into_finished_and_unfinished(heats)

    assign(socket,
      heats: heats,
      current_heat: heat_with_color_per_lane(current_heat),
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

  defp heat_with_color_per_lane(nil), do: nil

  defp heat_with_color_per_lane(heat) do
    colors =
      Enum.map(heat.lanes, fn lane ->
        index = rem(lane.racer_heat.car_number, length(@car_colors))
        Enum.at(@car_colors, index)
      end)

    Heat.add_color_to_each_lane(heat, colors)
  end

  defp heat_with_gray_color_per_lane(heat) do
    Heat.add_color_to_each_lane(heat, Enum.map(heat.lanes, fn _lane -> @gray_color end))
  end
end
