defmodule DerbyLive.RacingTest do
  use DerbyLive.DataCase, async: true

  alias DerbyLive.Racing
  alias DerbyLive.Racing.Event
  alias DerbyLive.Racing.Racer
  alias DerbyLive.Racing.RacerHeat

  def reload_events(events), do: Enum.map(events, &reload_event/1)

  def reload_event(event), do: Event |> Repo.get(event.id)

  def reload_racers(racers), do: Enum.map(racers, &reload_racer/1)

  def reload_racer(racer), do: Racer |> Repo.get(racer.id)

  def reload_racer_heats(racer_heats), do: Enum.map(racer_heats, &reload_racer_heat/1)

  def reload_racer_heat(racer_heat), do: RacerHeat |> Repo.get(racer_heat.id)

  def racer_to_map(%Racer{} = racer) do
    %{
      racer_id: racer.racer_id,
      first_name: racer.first_name,
      last_name: racer.last_name,
      rank: racer.rank,
      group: racer.group,
      car_name: racer.car_name,
      car_number: racer.car_number,
      event_id: racer.event_id
    }
  end

  def racer_heat_to_map(%RacerHeat{} = racer_heat) do
    %{
      result_id: racer_heat.result_id,
      car_number: racer_heat.car_number,
      finish_place: racer_heat.finish_place,
      finish_seconds: racer_heat.finish_seconds,
      finished_at: racer_heat.finished_at,
      group: racer_heat.group,
      lane_number: racer_heat.lane_number,
      racer_id: racer_heat.racer_id,
      heat_number: racer_heat.heat_number,
      event_id: racer_heat.event_id
    }
  end

  describe "racers" do
    test "list_racers/0 returns all racers" do
      racer = insert(:racer) |> reload_racer
      assert Racing.list_racers() == [racer]
    end

    test "list_racers_by_event/1 returns all racers for given event" do
      event = insert(:event)
      [racer1, racer2] = insert_list(2, :racer, event: event) |> reload_racers
      assert Racing.list_racers_by_event(event) == [racer1, racer2]
    end

    test "get_racer!/1 returns racer" do
      racer = insert(:racer) |> reload_racer
      assert Racing.get_racer!(racer.id) == racer
    end

    test "create_racer/1 creates racer" do
      event = insert(:event)
      attrs = params_for(:racer, event_id: event.id)
      {:ok, racer} = Racing.create_racer(attrs)

      assert racer_to_map(racer) == %{
               racer_id: attrs[:racer_id],
               first_name: attrs[:first_name],
               last_name: attrs[:last_name],
               rank: attrs[:rank],
               group: attrs[:group],
               car_name: attrs[:car_name],
               car_number: attrs[:car_number],
               event_id: event.id
             }
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

      assert racer_to_map(racer) == %{
               racer_id: attrs[:racer_id],
               first_name: attrs[:first_name],
               last_name: attrs[:last_name],
               rank: attrs[:rank],
               group: attrs[:group],
               car_name: attrs[:car_name],
               car_number: attrs[:car_number],
               event_id: racer.event_id
             }
    end

    test "update_or_create_racer/1 updates racer if it exists" do
      event = insert(:event)
      racer = insert(:racer, event: event)

      attrs = %{
        racer_id: racer.racer_id,
        first_name: "John",
        last_name: "Doe",
        rank: "Tigers",
        group: "Cubs",
        car_name: "The Tiger",
        car_number: 1,
        event_id: event.id
      }

      {:ok, racer} = Racing.update_or_create_racer(attrs)

      assert racer_to_map(racer) == %{
               racer_id: attrs[:racer_id],
               first_name: attrs[:first_name],
               last_name: attrs[:last_name],
               rank: attrs[:rank],
               group: attrs[:group],
               car_name: attrs[:car_name],
               car_number: attrs[:car_number],
               event_id: event.id
             }
    end

    test "update_or_create_racer/1 creates racer if it does not exist" do
      event = insert(:event)

      attrs = %{
        racer_id: 1,
        first_name: "John",
        last_name: "Doe",
        rank: "Tigers",
        group: "Cubs",
        car_name: "The Tiger",
        car_number: 1,
        event_id: event.id
      }

      {:ok, racer} = Racing.update_or_create_racer(attrs)

      assert racer_to_map(racer) == %{
               racer_id: attrs[:racer_id],
               first_name: attrs[:first_name],
               last_name: attrs[:last_name],
               rank: attrs[:rank],
               group: attrs[:group],
               car_name: attrs[:car_name],
               car_number: attrs[:car_number],
               event_id: event.id
             }
    end

    test "delete_racer/1 deletes racer" do
      racer = insert(:racer)
      assert {:ok, %Racer{}} = Racing.delete_racer(racer)
      assert_raise Ecto.NoResultsError, fn -> Racing.get_racer!(racer.id) end
    end
  end

  describe "racer_heats" do
    test "list_racer_heats/0 returns all racer_heats" do
      racer_heat = insert(:racer_heat) |> reload_racer_heat
      assert Racing.list_racer_heats() == [racer_heat]
    end

    test "list_racer_heats_by_event/1 returns all racer_heats for given event" do
      event = insert(:event)
      [racer_heat1, racer_heat2] = insert_list(2, :racer_heat, event: event) |> reload_racer_heats
      assert Racing.list_racer_heats_by_event(event) == [racer_heat1, racer_heat2]
    end

    test "get_racer_heat!/1 returns racer_heat" do
      racer_heat = insert(:racer_heat) |> reload_racer_heat
      assert Racing.get_racer_heat!(racer_heat.id) == racer_heat
    end

    test "create_racer_heat/1 creates racer_heat" do
      event = insert(:event)
      attrs = params_for(:racer_heat, event_id: event.id)
      {:ok, racer_heat} = Racing.create_racer_heat(attrs)

      assert racer_heat_to_map(racer_heat) == %{
               result_id: attrs[:result_id],
               group: attrs[:group],
               racer_id: attrs[:racer_id],
               heat_number: attrs[:heat_number],
               lane_number: attrs[:lane_number],
               car_number: attrs[:car_number],
               finish_seconds: attrs[:finish_seconds],
               finish_place: attrs[:finish_place],
               finished_at: attrs[:finished_at],
               event_id: event.id
             }
    end

    test "update_racer_heat/2 updates racer_heat" do
      event = insert(:event)
      racer_heat = insert(:racer_heat, event: event)

      attrs = %{
        result_id: 1,
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

      assert racer_heat_to_map(racer_heat) == %{
               result_id: attrs[:result_id],
               group: attrs[:group],
               racer_id: attrs[:racer_id],
               heat_number: attrs[:heat_number],
               lane_number: attrs[:lane_number],
               car_number: attrs[:car_number],
               finish_seconds: attrs[:finish_seconds],
               finish_place: attrs[:finish_place],
               finished_at: attrs[:finished_at],
               event_id: event.id
             }
    end

    test "update_or_create_racer_heat/1 updates racer_heat if it exists" do
      event = insert(:event)
      racer_heat = insert(:racer_heat, event: event)

      attrs = %{
        result_id: racer_heat.result_id,
        group: "Cubs",
        racer_id: 1,
        heat_number: 1,
        lane_number: 1,
        car_number: 1,
        finish_seconds: 1.0,
        finish_place: 1,
        finished_at: ~N[2023-01-01 00:00:00],
        event_id: event.id
      }

      {:ok, racer_heat} = Racing.update_or_create_racer_heat(attrs)

      assert racer_heat_to_map(racer_heat) == %{
               result_id: attrs[:result_id],
               group: attrs[:group],
               racer_id: attrs[:racer_id],
               heat_number: attrs[:heat_number],
               lane_number: attrs[:lane_number],
               car_number: attrs[:car_number],
               finish_seconds: attrs[:finish_seconds],
               finish_place: attrs[:finish_place],
               finished_at: attrs[:finished_at],
               event_id: event.id
             }
    end

    test "update_or_create_racer_heat/1 creates racer_heat if it does not exist" do
      event = insert(:event)

      attrs = %{
        result_id: 1,
        group: "Cubs",
        racer_id: 1,
        heat_number: 1,
        lane_number: 1,
        car_number: 1,
        finish_seconds: 1.0,
        finish_place: 1,
        finished_at: ~N[2023-01-01 00:00:00],
        event_id: event.id
      }

      {:ok, racer_heat} = Racing.update_or_create_racer_heat(attrs)

      assert racer_heat_to_map(racer_heat) == %{
               result_id: attrs[:result_id],
               group: attrs[:group],
               racer_id: attrs[:racer_id],
               heat_number: attrs[:heat_number],
               lane_number: attrs[:lane_number],
               car_number: attrs[:car_number],
               finish_seconds: attrs[:finish_seconds],
               finish_place: attrs[:finish_place],
               finished_at: attrs[:finished_at],
               event_id: event.id
             }
    end

    test "delete_racer_heat/1 deletes racer_heat" do
      racer_heat = insert(:racer_heat)
      assert {:ok, %RacerHeat{}} = Racing.delete_racer_heat(racer_heat)
      assert_raise Ecto.NoResultsError, fn -> Racing.get_racer_heat!(racer_heat.id) end
    end
  end

  describe "heats" do
    alias DerbyLive.Racing.{Lane, Heat}

    test "list_heats_for_event/1 returns all heats for an event" do
      event = insert(:event) |> reload_event
      [racer1, racer2, racer3, racer4] = insert_list(4, :racer, event: event) |> reload_racers

      racer_heat1 =
        insert(:racer_heat, racer_id: racer1.racer_id, heat_number: 1, event: event)
        |> reload_racer_heat

      racer_heat2 =
        insert(:racer_heat, racer_id: racer2.racer_id, heat_number: 1, event: event)
        |> reload_racer_heat

      racer_heat3 =
        insert(:racer_heat, racer_id: racer3.racer_id, heat_number: 1, event: event)
        |> reload_racer_heat

      racer_heat4 =
        insert(:racer_heat, racer_id: racer4.racer_id, heat_number: 1, event: event)
        |> reload_racer_heat

      assert Racing.list_heats_for_event(event) == [
               %Heat{
                 heat_number: 1,
                 lanes: [
                   %Lane{racer: racer1, racer_heat: racer_heat1},
                   %Lane{racer: racer2, racer_heat: racer_heat2},
                   %Lane{racer: racer3, racer_heat: racer_heat3},
                   %Lane{racer: racer4, racer_heat: racer_heat4}
                 ]
               }
             ]
    end
  end

  describe "events" do
    test "list_events/0 returns all events" do
      event1 = insert(:event)
      event2 = insert(:event)

      expected_events = reload_events([event1, event2])

      assert Racing.list_events() == expected_events
    end

    test "list_my_events/1 returns all events for given user" do
      user1 = insert(:user)
      user2 = insert(:user)
      event1 = insert(:event, user: user1)
      event2 = insert(:event, user: user2)

      [expected_event1, expected_event2] = reload_events([event1, event2])

      assert Racing.list_my_events(user1) == [expected_event1]
      assert Racing.list_my_events(user2) == [expected_event2]
    end

    test "get_event!/1 returns the event with given id" do
      event = insert(:event) |> reload_event
      assert Racing.get_event!(event.id) == event
    end

    test "get_event!/1 raises if event with given id does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Racing.get_event!(0) end
    end

    test "get_event_by_key/1 returns the event with given key" do
      event = insert(:event) |> reload_event
      assert Racing.get_event_by_key(event.key) == event
    end

    test "get_event_by_key/1 returns nil if event with given key does not exist" do
      assert Racing.get_event_by_key("some url prefix") == nil
    end

    test "create_event/1 with valid data creates a live event" do
      user = insert(:user)
      valid_attrs = %{"name" => "some name", "user_id" => user.id}

      assert {:ok, %Event{} = event} = Racing.create_event(valid_attrs)
      assert event.name == "some name"
      assert event.status == "live"
      assert String.length(event.key) >= 24
    end

    test "create_event/1 with invalid data returns error changeset" do
      invalid_attrs = %{}

      assert {:error, %Ecto.Changeset{}} = Racing.create_event(invalid_attrs)
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
      assert event.key == original_event.key
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = insert(:event) |> reload_event

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
      assert event.key == original_event.key
    end

    test "delete_event/1 deletes the event" do
      event = insert(:event)
      assert {:ok, %Event{}} = Racing.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Racing.get_event!(event.id) end
    end
  end
end
