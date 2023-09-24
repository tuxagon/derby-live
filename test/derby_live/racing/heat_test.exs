defmodule DerbyLive.HeatTest do
  use DerbyLive.DataCase, async: true

  alias DerbyLive.Racing.Heat
  alias DerbyLive.Racing.Lane

  test "add_color_to_each_lane/2 adds color to each lane" do
    heat = %Heat{
      heat_number: 1,
      lanes: [
        %Lane{},
        %Lane{}
      ]
    }

    colors = ["ff0000", "0000ff", "00ff00"]

    assert %Heat{
             heat_number: 1,
             lanes: [
               %Lane{car_color: "ff0000"},
               %Lane{car_color: "0000ff"}
             ]
           } = Heat.add_color_to_each_lane(heat, colors)
  end
end
