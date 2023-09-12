ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(DerbyLive.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:ex_machina)
Faker.start()
