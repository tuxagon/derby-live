defmodule DerbyLive.RacingTest do
  use DerbyLive.DataCase, async: true

  alias DerbyLive.Racing.Racer

  describe "racers" do
    alias DerbyLive.Racing.Racer

    test "list_racers/0 returns all racers" do
      racer = insert(:racer)
      assert DerbyLive.Racing.list_racers() == [racer]
    end

    test "get_racer!/1 returns racer" do
      racer = insert(:racer)
      assert DerbyLive.Racing.get_racer!(racer.id) == racer
    end

    test "create_racer/1 creates racer" do
      attrs = params_for(:racer)
      {:ok, racer} = DerbyLive.Racing.create_racer(attrs)
      assert racer.racer_id == attrs[:racer_id]
      assert racer.first_name == attrs[:first_name]
      assert racer.last_name == attrs[:last_name]
      assert racer.rank == attrs[:rank]
      assert racer.group == attrs[:group]
      assert racer.car_name == attrs[:car_name]
      assert racer.car_number == attrs[:car_number]
    end

    test "update_racer/2 updates racer" do
      racer = insert(:racer)

      attrs = %{
        racer_id: 1,
        first_name: "John",
        last_name: "Doe",
        rank: "Tigers",
        group: "Cubs",
        car_name: "The Tiger",
        car_number: 1
      }

      {:ok, racer} = DerbyLive.Racing.update_racer(racer, attrs)
      assert racer.racer_id == attrs[:racer_id]
      assert racer.first_name == attrs[:first_name]
      assert racer.last_name == attrs[:last_name]
      assert racer.rank == attrs[:rank]
      assert racer.group == attrs[:group]
      assert racer.car_name == attrs[:car_name]
      assert racer.car_number == attrs[:car_number]
    end

    test "delete_racer/1 deletes racer" do
      racer = insert(:racer)
      assert {:ok, %Racer{}} = DerbyLive.Racing.delete_racer(racer)
      assert_raise Ecto.NoResultsError, fn -> DerbyLive.Racing.get_racer!(racer.id) end
    end
  end

  describe "racer_heats" do
    alias DerbyLive.Racing.RacerHeat

    test "list_racer_heats/0 returns all racer_heats" do
      racer_heat = insert(:racer_heat)
      assert DerbyLive.Racing.list_racer_heats() == [racer_heat]
    end

    test "get_racer_heat!/1 returns racer_heat" do
      racer_heat = insert(:racer_heat)
      assert DerbyLive.Racing.get_racer_heat!(racer_heat.id) == racer_heat
    end

    test "create_racer_heat/1 creates racer_heat" do
      attrs = params_for(:racer_heat)
      {:ok, racer_heat} = DerbyLive.Racing.create_racer_heat(attrs)
      assert racer_heat.group == attrs[:group]
      assert racer_heat.racer_id == attrs[:racer_id]
      assert racer_heat.heat_number == attrs[:heat_number]
      assert racer_heat.lane_number == attrs[:lane_number]
      assert racer_heat.car_number == attrs[:car_number]
      assert racer_heat.finish_seconds == attrs[:finish_seconds]
      assert racer_heat.finish_place == attrs[:finish_place]
      assert racer_heat.finished_at == attrs[:finished_at]
    end

    test "update_racer_heat/2 updates racer_heat" do
      racer_heat = insert(:racer_heat)

      attrs = %{
        group: "Cubs",
        racer_id: 1,
        heat_number: 1,
        lane_number: 1,
        car_number: 1,
        finish_seconds: 1.0,
        finish_place: 1,
        finished_at: ~N[2023-01-01 00:00:00]
      }

      {:ok, racer_heat} = DerbyLive.Racing.update_racer_heat(racer_heat, attrs)
      assert racer_heat.group == attrs[:group]
      assert racer_heat.racer_id == attrs[:racer_id]
      assert racer_heat.heat_number == attrs[:heat_number]
      assert racer_heat.lane_number == attrs[:lane_number]
      assert racer_heat.car_number == attrs[:car_number]
      assert racer_heat.finish_seconds == attrs[:finish_seconds]
      assert racer_heat.finish_place == attrs[:finish_place]
      assert racer_heat.finished_at == attrs[:finished_at]
    end

    test "delete_racer_heat/1 deletes racer_heat" do
      racer_heat = insert(:racer_heat)
      assert {:ok, %RacerHeat{}} = DerbyLive.Racing.delete_racer_heat(racer_heat)
      assert_raise Ecto.NoResultsError, fn -> DerbyLive.Racing.get_racer_heat!(racer_heat.id) end
    end
  end

  describe "heats" do
    test "list_heats/0 returns all heats as map" do
      [racer1, racer2, racer3, racer4] = insert_list(4, :racer)
      racer_heat1 = insert(:racer_heat, racer_id: racer1.racer_id, heat_number: 1)
      racer_heat2 = insert(:racer_heat, racer_id: racer2.racer_id, heat_number: 1)
      racer_heat3 = insert(:racer_heat, racer_id: racer3.racer_id, heat_number: 1)
      racer_heat4 = insert(:racer_heat, racer_id: racer4.racer_id, heat_number: 1)

      assert DerbyLive.Racing.list_heats() == %{
               1 => [
                 {racer1, racer_heat1},
                 {racer2, racer_heat2},
                 {racer3, racer_heat3},
                 {racer4, racer_heat4}
               ]
             }
    end
  end
end
