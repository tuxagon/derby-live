# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DerbyLive.Repo.insert!(%DerbyLive.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

for n <- 1..24 do
  DerbyLive.Repo.insert!(%DerbyLive.Racing.Racer{
    racer_id: n,
    first_name: Faker.Name.first_name(),
    last_name: Faker.Name.last_name(),
    rank: Enum.random(["Lions", "Tigers", "Wolves", "Bears", "Webelos", "Arrow of Light"]),
    group: "Cubs",
    car_name: Faker.Company.name(),
    car_number: n + 100
  })
end
