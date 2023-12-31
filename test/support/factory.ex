defmodule DerbyLive.Factory do
  use ExMachina.Ecto, repo: DerbyLive.Repo

  alias DerbyLive.Account.User
  alias DerbyLive.Racing.Event
  alias DerbyLive.Racing.Racer
  alias DerbyLive.Racing.RacerHeat

  @ranks ["Lions", "Tigers", "Wolves", "Bears", "Webelos", "Arrow of Light"]

  def racer_factory do
    %Racer{
      racer_id: sequence(:racer_id, &(&1 + 1), start_at: 1),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      rank: sequence(:rank, @ranks),
      group: "Cubs",
      car_name: nil,
      car_number: sequence(:car_number, &(&1 + 1), start_at: 1),
      event: build(:event)
    }
  end

  def racer_heat_factory do
    %RacerHeat{
      result_id: sequence(:racer_id, &(&1 + 1), start_at: 1),
      group: "Cubs",
      racer_id: sequence(:racer_id, &(&1 + 1), start_at: 1),
      heat_number: sequence(:heat_number, &(&1 + 1), start_at: 1),
      lane_number: sequence(:lane_number, &(&1 + 1), start_at: 1),
      car_number: sequence(:car_number, &(&1 + 1), start_at: 1),
      finish_seconds: nil,
      finish_place: nil,
      finished_at: nil,
      event: build(:event)
    }
  end

  def user_factory do
    %User{
      name: Faker.Person.name(),
      email: Faker.Internet.email(),
      api_key: Faker.UUID.v4(),
      auth_token: Faker.UUID.v4(),
      auth_token_expires_at:
        DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
    }
  end

  def event_factory do
    %Event{
      name: sequence(:name, &"Sample Event#{&1}"),
      status: "live",
      key: Faker.UUID.v4(),
      user: build(:user)
    }
  end
end
