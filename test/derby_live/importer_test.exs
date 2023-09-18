defmodule DerbyLive.ImporterTest do
  use DerbyLive.DataCase, async: true

  alias DerbyLive.Importer

  test "import_racers/2 imports racers" do
    event = insert(:event)

    racers = [
      %{
        "racer_id" => 1,
        "first_name" => "John",
        "last_name" => "Doe",
        "rank" => "Tigers",
        "group" => "Cubs",
        "car_name" => "The Tiger",
        "car_number" => 101
      }
    ]

    assert [{:ok, racer}] = Importer.import_racers(racers, event)
    assert racer.racer_id == 1
    assert racer.first_name == "John"
    assert racer.last_name == "Doe"
    assert racer.rank == "Tigers"
    assert racer.group == "Cubs"
    assert racer.car_name == "The Tiger"
    assert racer.car_number == 101
    assert racer.event_id == event.id
  end

  test "import_racer_heats/2 imports racer heats" do
    event = insert(:event)

    racer_heats = [
      %{
        "racer_id" => 1,
        "group" => "Cubs",
        "heat_number" => 1,
        "lane_number" => 1,
        "car_number" => 101,
        "finish_seconds" => 2.0,
        "finish_place" => 1,
        "finished_at" => "2019-01-01 12:00:00"
      }
    ]

    assert [{:ok, racer_heat}] = Importer.import_racer_heats(racer_heats, event)
    assert racer_heat.racer_id == 1
    assert racer_heat.group == "Cubs"
    assert racer_heat.heat_number == 1
    assert racer_heat.lane_number == 1
    assert racer_heat.car_number == 101
    assert racer_heat.finish_seconds == 2.0
    assert racer_heat.finish_place == 1
    assert racer_heat.finished_at == ~N[2019-01-01 12:00:00]
    assert racer_heat.event_id == event.id
  end
end
