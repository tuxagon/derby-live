defmodule DerbyLive.Factory do
  use ExMachina.Ecto, repo: DerbyLive.Repo

  alias DerbyLive.Racing.Racer

  def racer_factory do
    %Racer{
      racer_id: sequence(:racer_id, &(&1 + 1), start_at: 1),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      rank: sequence(:rank, ["Lions", "Tigers", "Wolves", "Bears", "Webelos", "Arrow of Light"]),
      group: "Cubs",
      car_name: nil,
      car_number: sequence(:car_number, &(&1 + 1), start_at: 1)
    }
  end
end
