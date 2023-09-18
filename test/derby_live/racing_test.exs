defmodule DerbyLive.RacingTest do
  use DerbyLive.DataCase, async: true

  alias DerbyLive.Racing

  describe "racers" do
    alias DerbyLive.Racing.Racer

    test "list_racers/0 returns all racers" do
      racer = insert(:racer)
      assert Racing.list_racers() == [racer]
    end

    test "get_racer!/1 returns racer" do
      racer = insert(:racer)
      assert Racing.get_racer!(racer.id) == racer
    end

    test "create_racer/1 creates racer" do
      attrs = params_for(:racer)
      {:ok, racer} = Racing.create_racer(attrs)
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

      {:ok, racer} = Racing.update_racer(racer, attrs)
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
      assert {:ok, %Racer{}} = Racing.delete_racer(racer)
      assert_raise Ecto.NoResultsError, fn -> Racing.get_racer!(racer.id) end
    end
  end

  describe "racer_heats" do
    alias DerbyLive.Racing.RacerHeat

    test "list_racer_heats/0 returns all racer_heats" do
      racer_heat = insert(:racer_heat)
      assert Racing.list_racer_heats() == [racer_heat]
    end

    test "get_racer_heat!/1 returns racer_heat" do
      racer_heat = insert(:racer_heat)
      assert Racing.get_racer_heat!(racer_heat.id) == racer_heat
    end

    test "create_racer_heat/1 creates racer_heat" do
      attrs = params_for(:racer_heat)
      {:ok, racer_heat} = Racing.create_racer_heat(attrs)
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

      {:ok, racer_heat} = Racing.update_racer_heat(racer_heat, attrs)
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
      assert {:ok, %RacerHeat{}} = Racing.delete_racer_heat(racer_heat)
      assert_raise Ecto.NoResultsError, fn -> Racing.get_racer_heat!(racer_heat.id) end
    end
  end

  describe "heats" do
    test "list_heats/0 returns all heats as map" do
      [racer1, racer2, racer3, racer4] = insert_list(4, :racer)
      racer_heat1 = insert(:racer_heat, racer_id: racer1.racer_id, heat_number: 1)
      racer_heat2 = insert(:racer_heat, racer_id: racer2.racer_id, heat_number: 1)
      racer_heat3 = insert(:racer_heat, racer_id: racer3.racer_id, heat_number: 1)
      racer_heat4 = insert(:racer_heat, racer_id: racer4.racer_id, heat_number: 1)

      assert Racing.list_heats() == %{
               1 => [
                 {racer1, racer_heat1},
                 {racer2, racer_heat2},
                 {racer3, racer_heat3},
                 {racer4, racer_heat4}
               ]
             }
    end
  end

  describe "events" do
    alias DerbyLive.Racing.Event

    test "list_events/0 returns all events" do
      event = insert(:event)
      assert Racing.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = insert(:event)
      assert Racing.get_event!(event.id) == event
    end

    test "get_event!/1 raises if event with given id does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Racing.get_event!(0) end
    end

    test "get_event_by_url_prefix/1 returns the event with given url_prefix" do
      event = insert(:event)
      assert Racing.get_event_by_url_prefix(event.url_prefix) == event
    end

    test "get_event_by_url_prefix/1 returns nil if event with given url_prefix does not exist" do
      assert Racing.get_event_by_url_prefix("some url prefix") == nil
    end

    test "create_live_event/1 with valid data creates a live event" do
      valid_attrs = %{"name" => "some name"}

      assert {:ok, %Event{} = event} = Racing.create_live_event(valid_attrs)
      assert event.name == "some name"
      assert event.status == "live"
      assert String.length(event.url_prefix) >= 24
    end

    test "create_event/1 with invalid data returns error changeset" do
      invalid_attrs = %{}

      assert {:error, %Ecto.Changeset{}} = Racing.create_live_event(invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = insert(:event)

      original_event = event

      update_attrs = %{
        name: "new name"
      }

      assert {:ok, %Event{} = event} = Racing.update_event(event, update_attrs)
      assert event.name == "new name"
      assert event.status == original_event.status
      assert event.url_prefix == original_event.url_prefix
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = insert(:event)

      update_attrs = %{
        name: nil
      }

      assert {:error, %Ecto.Changeset{}} = Racing.update_event(event, update_attrs)
      assert event == Racing.get_event!(event.id)
    end

    test "archive_event/1 archives the event" do
      event = insert(:event)
      original_event = event
      assert {:ok, %Event{} = event} = Racing.archive_event(event)
      assert event.name == original_event.name
      assert event.status == "archived"
      assert event.url_prefix == original_event.url_prefix
    end

    test "delete_event/1 deletes the event" do
      event = insert(:event)
      assert {:ok, %Event{}} = Racing.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Racing.get_event!(event.id) end
    end
  end
end
