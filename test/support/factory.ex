defmodule DerbyLive.Factory do
  @moduledoc """
  Test factory for creating Ash resources.

  Uses Ash.Changeset.for_create with the proper changeset pattern.
  """

  alias DerbyLive.Accounts.User
  alias DerbyLive.Racing.Event
  alias DerbyLive.Racing.Racer
  alias DerbyLive.Racing.RacerHeat

  @ranks ["Lions", "Tigers", "Wolves", "Bears", "Webelos", "Arrow of Light"]

  def build_user(attrs \\ %{}) do
    defaults = %{
      name: Faker.Person.name(),
      email: Faker.Internet.email()
    }

    Map.merge(defaults, attrs)
  end

  def insert_user(attrs \\ %{}) do
    attrs = build_user(attrs)

    User
    |> Ash.Changeset.for_create(:register, attrs)
    |> Ash.create!()
  end

  def build_event(attrs \\ %{}) do
    defaults = %{
      name: "Sample Event #{System.unique_integer([:positive])}"
    }

    Map.merge(defaults, attrs)
  end

  def insert_event(attrs \\ %{}, user \\ nil) do
    user = user || insert_user()
    attrs = build_event(attrs)

    # Pass user_id as part of the params - Ash will match it to the argument
    params = Map.put(attrs, :user_id, user.id)

    Event
    |> Ash.Changeset.for_create(:create, params)
    |> Ash.create!()
  end

  def build_racer(attrs \\ %{}) do
    defaults = %{
      racer_id: System.unique_integer([:positive]),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      rank: Enum.random(@ranks),
      group: "Cubs",
      car_number: System.unique_integer([:positive])
    }

    Map.merge(defaults, attrs)
  end

  def insert_racer(attrs \\ %{}, event \\ nil) do
    event = event || insert_event()
    attrs = build_racer(attrs)

    params = Map.put(attrs, :event_id, event.id)

    Racer
    |> Ash.Changeset.for_create(:create, params)
    |> Ash.create!()
  end

  def build_racer_heat(attrs \\ %{}) do
    defaults = %{
      result_id: System.unique_integer([:positive]),
      group: "Cubs",
      racer_id: System.unique_integer([:positive]),
      heat_number: 1,
      lane_number: 1,
      car_number: System.unique_integer([:positive]),
      finish_seconds: nil,
      finish_place: nil,
      finished_at: nil
    }

    Map.merge(defaults, attrs)
  end

  def insert_racer_heat(attrs \\ %{}, event \\ nil) do
    event = event || insert_event()
    attrs = build_racer_heat(attrs)

    params = Map.put(attrs, :event_id, event.id)

    RacerHeat
    |> Ash.Changeset.for_create(:create, params)
    |> Ash.create!()
  end
end
