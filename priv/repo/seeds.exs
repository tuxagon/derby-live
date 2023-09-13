# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

alias DerbyLive.Repo
alias DerbyLive.Racing.Racer
alias DerbyLive.Racing.RacerHeat

Repo.delete_all(Racer)
Repo.delete_all(RacerHeat)

num_racers = 24

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
