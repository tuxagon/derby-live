defmodule DerbyLive.ImporterTest do
  use DerbyLive.DataCase, async: true

  import DerbyLive.Factory

  alias DerbyLive.Importer
  alias DerbyLive.Racing.Racer
  alias DerbyLive.Racing.RacerHeat

  def racer_to_map(%Racer{} = racer) do
    %{
      "racer_id" => racer.racer_id,
      "first_name" => racer.first_name,
      "last_name" => racer.last_name,
      "rank" => racer.rank,
      "group" => racer.group,
      "car_name" => racer.car_name,
      "car_number" => racer.car_number,
      "event_id" => racer.event_id
    }
  end

  def racer_heat_to_map(%RacerHeat{} = racer_heat) do
    %{
      "result_id" => racer_heat.result_id,
      "car_number" => racer_heat.car_number,
      "finish_place" => racer_heat.finish_place,
      "finish_seconds" => racer_heat.finish_seconds,
      "finished_at" => racer_heat.finished_at,
      "group" => racer_heat.group,
      "lane_number" => racer_heat.lane_number,
      "racer_id" => racer_heat.racer_id,
      "heat_number" => racer_heat.heat_number,
      "event_id" => racer_heat.event_id
    }
  end

  test "import_racers/2 imports racers" do
    event = insert_event()

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

    assert [racer] = Importer.import_racers(racers, event)

    assert racer_to_map(racer) == %{
             "racer_id" => 1,
             "first_name" => "John",
             "last_name" => "Doe",
             "rank" => "Tigers",
             "group" => "Cubs",
             "car_name" => "The Tiger",
             "car_number" => 101,
             "event_id" => event.id
           }
  end

  test "import_racers/2 updates existing racer instead of creating new" do
    event = insert_event()
    existing_racer = insert_racer(%{racer_id: 999}, event)

    racers = [
      %{
        "racer_id" => 999,
        "first_name" => "John",
        "last_name" => "Doe",
        "rank" => "Tigers",
        "group" => "Cubs",
        "car_name" => "The Tiger",
        "car_number" => 101
      }
    ]

    count_before = Repo.aggregate(Racer, :count, :id)

    assert [racer] = Importer.import_racers(racers, event)

    count_after = Repo.aggregate(Racer, :count, :id)

    assert count_before == count_after
    assert racer.id == existing_racer.id

    assert racer_to_map(racer) == %{
             "racer_id" => 999,
             "first_name" => "John",
             "last_name" => "Doe",
             "rank" => "Tigers",
             "group" => "Cubs",
             "car_name" => "The Tiger",
             "car_number" => 101,
             "event_id" => event.id
           }
  end

  test "import_racer_heats/2 imports racer heats" do
    event = insert_event()

    racer_heats = [
      %{
        "result_id" => 1,
        "car_number" => 101,
        "finish_place" => 1,
        "finish_seconds" => 2.0,
        "finished_at_unix" => 1_644_678_240,
        "group" => "Cubs",
        "lane_number" => 1,
        "racer_id" => 1,
        "heat_number" => 1
      },
      %{
        "result_id" => 2,
        "car_number" => 102,
        "finish_place" => nil,
        "finish_seconds" => nil,
        "finished_at_unix" => nil,
        "group" => "Cubs",
        "lane_number" => 2,
        "racer_id" => 2,
        "heat_number" => 1
      }
    ]

    assert [racer_heat_1, racer_heat_2] = Importer.import_racer_heats(racer_heats, event)

    assert racer_heat_to_map(racer_heat_1) == %{
             "result_id" => 1,
             "car_number" => 101,
             "finish_place" => 1,
             "finish_seconds" => 2.0,
             "finished_at" => ~N[2022-02-12 15:04:00],
             "group" => "Cubs",
             "lane_number" => 1,
             "racer_id" => 1,
             "heat_number" => 1,
             "event_id" => event.id
           }

    assert racer_heat_to_map(racer_heat_2) == %{
             "result_id" => 2,
             "car_number" => 102,
             "finish_place" => nil,
             "finish_seconds" => nil,
             "finished_at" => nil,
             "group" => "Cubs",
             "lane_number" => 2,
             "racer_id" => 2,
             "heat_number" => 1,
             "event_id" => event.id
           }
  end

  test "import_racer_heats/2 updates existing racer heat instead of creating new" do
    event = insert_event()
    existing = insert_racer_heat(%{result_id: 888}, event)

    racer_heats = [
      %{
        "result_id" => 888,
        "car_number" => "101",
        "finish_place" => 1,
        "finish_seconds" => 2.0,
        "finished_at_unix" => 1_644_678_240,
        "group" => "Cubs",
        "lane_number" => 1,
        "racer_id" => 1,
        "heat_number" => 1
      }
    ]

    count_before = Repo.aggregate(RacerHeat, :count, :id)

    assert [racer_heat] = Importer.import_racer_heats(racer_heats, event)

    count_after = Repo.aggregate(RacerHeat, :count, :id)

    assert count_before == count_after
    assert racer_heat.id == existing.id

    assert racer_heat_to_map(racer_heat) == %{
             "result_id" => 888,
             "car_number" => 101,
             "finish_place" => 1,
             "finish_seconds" => 2.0,
             "finished_at" => ~N[2022-02-12 15:04:00],
             "group" => "Cubs",
             "lane_number" => 1,
             "racer_id" => 1,
             "heat_number" => 1,
             "event_id" => event.id
           }
  end
end
