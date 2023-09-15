defmodule DerbyLive.Importer do
  alias DerbyLive.Racing
  alias DerbyLive.Racing.{Racer, RacerHeat}

  def import_racers(racers) do
    racers
    |> Enum.map(&cast_data(&1, Racer))
    |> Enum.map(&Racing.create_racer/1)
  end

  def import_racer_heats(racer_heats) do
    racer_heats
    |> Enum.map(&cast_data(&1, RacerHeat))
    |> Enum.map(&Racing.create_racer_heat/1)
  end

  defp cast_data(data, mod) do
    data
    |> Map.take(mod.importable_fields)
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end
end
