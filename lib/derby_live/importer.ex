defmodule DerbyLive.Importer do
  alias DerbyLive.Racing
  alias DerbyLive.Racing.{Racer, RacerHeat}

  def import_racers(racers, event) do
    racers
    |> Enum.map(&cast_data(&1, Racer))
    |> Enum.map(fn racer -> Map.put(racer, :event_id, event.id) end)
    |> Enum.map(&Racing.update_or_create_racer/1)
  end

  def import_racer_heats(racer_heats, event) do
    racer_heats
    |> Enum.map(fn racer_heat ->
      racer_heat |> Map.put("finished_at", unix_to_naive_datetime(racer_heat["finished_at_unix"]))
    end)
    |> Enum.map(&cast_data(&1, RacerHeat))
    |> Enum.map(fn racer_heat -> Map.put(racer_heat, :event_id, event.id) end)
    |> Enum.map(&Racing.update_or_create_racer_heat/1)
  end

  defp cast_data(data, mod) do
    data
    |> Map.take(mod.importable_fields())
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end

  defp unix_to_naive_datetime(nil), do: nil

  defp unix_to_naive_datetime(unix) do
    unix
    |> DateTime.from_unix!()
    |> DateTime.to_naive()
  end
end
