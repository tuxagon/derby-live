# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

alias DerbyLive.Account.User
alias DerbyLive.Repo
alias DerbyLive.Racing.Racer
alias DerbyLive.Racing.RacerHeat

Repo.delete_all(User)
Repo.delete_all(Racer)
Repo.delete_all(RacerHeat)

user = %User{
  name: "Admin",
  email: "admin@example.com"
}

Repo.insert!(user)

num_racers = 24
num_lanes = 4

group = "Cubs"
ranks = ["Lions", "Tigers", "Wolves", "Bears", "Webelos", "Arrow of Light"]

1..num_racers
|> Enum.each(fn car_number ->
  first_name = Faker.Person.first_name()
  last_name = Faker.Person.last_name()

  car_name =
    if Enum.random([true, false]), do: "#{Faker.Color.name()} #{Faker.Pokemon.name()}", else: nil

  rank = Enum.random(ranks)

  racer = %Racer{
    racer_id: car_number,
    group: group,
    first_name: first_name,
    last_name: last_name,
    rank: rank,
    car_name: car_name,
    car_number: car_number + 100
  }

  Repo.insert!(racer)
end)

racers = Repo.all(Racer)

first_heats =
  racers
  |> Enum.chunk_every(num_lanes, num_lanes, [])
  |> Enum.shuffle()
  |> Enum.with_index(1)
  |> Enum.map(fn {heat_racers, heat_number} ->
    {heat_racers
     |> Enum.shuffle()
     |> Enum.with_index(1)
     |> Enum.shuffle()
     |> Enum.with_index(1), heat_number}
  end)

first_heats
|> Enum.map(fn {heat, heat_number} ->
  finishes =
    Enum.map(1..4, fn _ -> Float.round(2.0 + :rand.uniform() * 4.0, 2) end) |> Enum.sort()

  heat
  |> Enum.map(fn {{racer, place}, lane_number} ->
    %RacerHeat{
      group: group,
      racer_id: racer.racer_id,
      heat_number: heat_number,
      lane_number: lane_number,
      car_number: racer.car_number,
      finish_seconds: Enum.at(finishes, place - 1),
      finish_place: place,
      finished_at: NaiveDateTime.local_now()
    }
  end)
  |> Enum.each(&Repo.insert!/1)
end)
