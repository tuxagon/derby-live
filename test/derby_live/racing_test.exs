defmodule DerbyLive.RacingTest do
  use DerbyLive.DataCase, async: true

  import DerbyLive.Factory

  require Ash.Query

  alias DerbyLive.Racing.Event
  alias DerbyLive.Racing.Racer
  alias DerbyLive.Racing.RacerHeat

  describe "Event resource" do
    test "create action creates an event with key" do
      user = insert_user()

      {:ok, event} =
        Event
        |> Ash.Changeset.for_create(:create, %{name: "Test Event", user_id: user.id})
        |> Ash.create()

      assert event.name == "Test Event"
      assert event.status == "live"
      assert is_binary(event.key)
      assert String.length(event.key) >= 24
    end

    test "by_key action finds event by key" do
      event = insert_event()

      found =
        Event
        |> Ash.Query.for_read(:by_key, %{key: event.key})
        |> Ash.read_one!()

      assert found.id == event.id
    end

    test "for_user action returns events for user" do
      user = insert_user()
      event1 = insert_event(%{name: "Alpha"}, user)
      event2 = insert_event(%{name: "Beta"}, user)
      # Different user
      _other_event = insert_event()

      events =
        Event
        |> Ash.Query.for_read(:for_user, %{user_id: user.id})
        |> Ash.read!()

      assert length(events) == 2
      assert Enum.map(events, & &1.id) == [event1.id, event2.id]
    end

    test "update action updates event" do
      event = insert_event()

      {:ok, updated} =
        event
        |> Ash.Changeset.for_update(:update, %{name: "New Name"})
        |> Ash.update()

      assert updated.name == "New Name"
      assert updated.status == event.status
      assert updated.key == event.key
    end

    test "archive action sets status to archived" do
      event = insert_event()

      {:ok, archived} =
        event
        |> Ash.Changeset.for_update(:archive, %{})
        |> Ash.update()

      assert archived.status == "archived"
      assert archived.name == event.name
    end

    test "destroy action deletes event" do
      event = insert_event()
      :ok = Ash.destroy!(event)

      assert_raise Ash.Error.Invalid, fn ->
        Ash.get!(Event, event.id)
      end
    end
  end

  describe "Racer resource" do
    test "create action creates racer" do
      event = insert_event()
      attrs = build_racer()

      {:ok, racer} =
        Racer
        |> Ash.Changeset.for_create(:create, Map.put(attrs, :event_id, event.id))
        |> Ash.create()

      assert racer.first_name == attrs.first_name
      assert racer.last_name == attrs.last_name
      assert racer.event_id == event.id
    end

    test "for_event action returns racers for event" do
      event = insert_event()
      racer1 = insert_racer(%{car_number: 1}, event)
      racer2 = insert_racer(%{car_number: 2}, event)
      # Different event
      _other = insert_racer()

      racers =
        Racer
        |> Ash.Query.for_read(:for_event, %{event_id: event.id})
        |> Ash.read!()

      assert length(racers) == 2
      assert racer1.id in Enum.map(racers, & &1.id)
      assert racer2.id in Enum.map(racers, & &1.id)
    end

    test "upsert action creates new racer" do
      event = insert_event()
      attrs = build_racer(%{racer_id: 999})

      {:ok, racer} =
        Racer
        |> Ash.Changeset.for_create(:upsert, Map.put(attrs, :event_id, event.id))
        |> Ash.create()

      assert racer.racer_id == 999
      assert racer.event_id == event.id
    end

    test "upsert action updates existing racer" do
      event = insert_event()
      existing = insert_racer(%{racer_id: 888, first_name: "Old"}, event)

      {:ok, updated} =
        Racer
        |> Ash.Changeset.for_create(:upsert, %{
          racer_id: 888,
          first_name: "New",
          last_name: existing.last_name,
          rank: existing.rank,
          group: existing.group,
          car_number: existing.car_number,
          event_id: event.id
        })
        |> Ash.create()

      assert updated.id == existing.id
      assert updated.first_name == "New"
    end
  end

  describe "RacerHeat resource" do
    test "create action creates racer heat" do
      event = insert_event()
      attrs = build_racer_heat()

      {:ok, racer_heat} =
        RacerHeat
        |> Ash.Changeset.for_create(:create, Map.put(attrs, :event_id, event.id))
        |> Ash.create()

      assert racer_heat.heat_number == attrs.heat_number
      assert racer_heat.event_id == event.id
    end

    test "for_event action returns racer heats for event" do
      event = insert_event()
      rh1 = insert_racer_heat(%{heat_number: 1, lane_number: 1}, event)
      rh2 = insert_racer_heat(%{heat_number: 1, lane_number: 2}, event)
      # Different event
      _other = insert_racer_heat()

      racer_heats =
        RacerHeat
        |> Ash.Query.for_read(:for_event, %{event_id: event.id})
        |> Ash.read!()

      assert length(racer_heats) == 2
      assert rh1.id in Enum.map(racer_heats, & &1.id)
      assert rh2.id in Enum.map(racer_heats, & &1.id)
    end

    test "upsert action creates new racer heat" do
      event = insert_event()
      attrs = build_racer_heat(%{result_id: 999})

      {:ok, racer_heat} =
        RacerHeat
        |> Ash.Changeset.for_create(:upsert, Map.put(attrs, :event_id, event.id))
        |> Ash.create()

      assert racer_heat.result_id == 999
      assert racer_heat.event_id == event.id
    end

    test "upsert action updates existing racer heat" do
      event = insert_event()
      existing = insert_racer_heat(%{result_id: 888, finish_place: nil}, event)

      attrs =
        Map.merge(
          build_racer_heat(%{result_id: 888, finish_place: 1}),
          %{event_id: event.id}
        )

      {:ok, updated} =
        RacerHeat
        |> Ash.Changeset.for_create(:upsert, attrs)
        |> Ash.create()

      assert updated.id == existing.id
      assert updated.finish_place == 1
    end
  end
end
