defmodule DerbyLive.Racing.Heat do
  defstruct [:heat_number, :lanes]

  def sort_lanes_asc(%__MODULE__{} = heat) do
    %__MODULE__{heat | lanes: Enum.sort_by(heat.lanes, & &1.racer_heat.lane_number)}
  end

  def add_color_to_each_lane(%__MODULE__{} = heat, colors) when is_list(colors) do
    {_, updated_heat} =
      Map.get_and_update(heat, :lanes, fn current_lanes ->
        updated_lanes =
          current_lanes
          |> Enum.zip(colors)
          |> Enum.map(fn {lane, color} -> Map.put(lane, :car_color, color) end)

        {current_lanes, updated_lanes}
      end)

    updated_heat
  end

  def add_color_to_each_lane(heat, _), do: heat
end
