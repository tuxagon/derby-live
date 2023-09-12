defmodule DerbyLive.RacingTest do
  alias DerbyLive.Racing.Racer
  use DerbyLive.DataCase, async: true

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
end
