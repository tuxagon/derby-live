defmodule DerbyLive.SyncSimulator.Generator do
  @moduledoc """
  Generates synthetic derby race data for testing.

  Takes the structure from a real SQLite database and generates
  fake racer names and realistic race times while preserving
  the heat schedule and lane assignments.
  """

  alias DerbyLive.SyncSimulator.SqliteParser

  @doc """
  Generates synthetic race data from a SQLite database structure.

  Returns a list of snapshots, where each snapshot represents the state
  after one more heat has completed.

  ## Options
  - `:min_time` - Minimum finish time in seconds (default: 2.5)
  - `:max_time` - Maximum finish time in seconds (default: 4.0)
  """
  def generate_from_sqlite(db_path, opts \\ []) do
    {:ok, structure} = SqliteParser.parse(db_path)

    # Also get racer structure
    {:ok, conn} = Exqlite.Sqlite3.open(db_path, mode: :readonly)
    racer_structure = SqliteParser.extract_racers(conn)
    Exqlite.Sqlite3.close(conn)

    generate(structure, racer_structure, opts)
  end

  @doc """
  Generates synthetic race data from extracted structure.

  ## Parameters
  - `structure` - Map with :ranks, :heats, :lane_count, :class_name
  - `racer_structure` - List of racer maps with :racer_id, :car_number, :rank, :group
  - `opts` - Generation options
  """
  def generate(structure, racer_structure, opts \\ []) do
    min_time = Keyword.get(opts, :min_time, 2.5)
    max_time = Keyword.get(opts, :max_time, 4.0)

    # Generate fake racers with same structure but fake names
    racers = generate_fake_racers(racer_structure)

    # Create a map of racer_id -> fake racer for lookup
    racer_map = Map.new(racers, fn r -> {r.racer_id, r} end)

    # Generate incremental snapshots
    heats = structure.heats
    heat_count = length(heats)

    snapshots =
      0..heat_count
      |> Enum.map(fn completed_heat_count ->
        racer_heats =
          generate_racer_heats_for_snapshot(
            heats,
            racer_map,
            completed_heat_count,
            min_time,
            max_time
          )

        %{
          racers: format_racers_for_api(racers),
          racer_heats: format_racer_heats_for_api(racer_heats)
        }
      end)

    {:ok, snapshots}
  end

  @doc """
  Generates fake racers with synthetic names but preserving structure.

  Car names are set to nil by default since most scouts don't name their cars.
  """
  def generate_fake_racers(racer_structure) do
    racer_structure
    |> Enum.map(fn racer ->
      %{
        racer_id: racer.racer_id,
        car_number: racer.car_number,
        first_name: Faker.Person.first_name(),
        last_name: Faker.Person.last_name(),
        car_name: nil,
        rank: racer.rank,
        group: racer.group
      }
    end)
  end

  @doc """
  Generates a realistic finish time between min and max seconds.
  """
  def generate_finish_time(min_time, max_time) do
    range = max_time - min_time

    (min_time + :rand.uniform() * range)
    |> Float.round(3)
  end

  # Generate racer_heats for a specific snapshot (with N heats completed)
  defp generate_racer_heats_for_snapshot(
         heats,
         racer_map,
         completed_heat_count,
         min_time,
         max_time
       ) do
    base_time = System.os_time(:second)

    heats
    |> Enum.flat_map(fn heat ->
      is_completed = heat.heat_number <= completed_heat_count

      heat.lanes
      |> Enum.map(fn lane ->
        racer = Map.get(racer_map, lane.racer_id)

        if is_completed do
          # Generate times for this heat
          generate_completed_lane(heat, lane, racer, base_time, min_time, max_time)
        else
          # Heat not yet completed
          %{
            result_id: lane.result_id,
            racer_id: lane.racer_id,
            heat_number: heat.heat_number,
            lane_number: lane.lane_number,
            car_number: racer && racer.car_number,
            group: racer && racer.group,
            finish_seconds: nil,
            finish_place: nil,
            finished_at_unix: nil
          }
        end
      end)
    end)
    |> assign_finish_places()
  end

  defp generate_completed_lane(heat, lane, racer, base_time, min_time, max_time) do
    finish_time = generate_finish_time(min_time, max_time)
    # Each heat happens ~30 seconds apart
    finished_at = base_time + heat.heat_number * 30

    %{
      result_id: lane.result_id,
      racer_id: lane.racer_id,
      heat_number: heat.heat_number,
      lane_number: lane.lane_number,
      car_number: racer && racer.car_number,
      group: racer && racer.group,
      finish_seconds: finish_time,
      # Will be assigned later
      finish_place: nil,
      finished_at_unix: finished_at
    }
  end

  # Assign finish places based on finish times within each heat
  defp assign_finish_places(racer_heats) do
    racer_heats
    |> Enum.group_by(& &1.heat_number)
    |> Enum.flat_map(fn {_heat_number, heat_entries} ->
      # Sort by finish time (nil times go last)
      sorted =
        heat_entries
        |> Enum.sort_by(fn entry ->
          entry.finish_seconds || 999.0
        end)

      # Assign places
      sorted
      |> Enum.with_index(1)
      |> Enum.map(fn {entry, place} ->
        if entry.finish_seconds do
          %{entry | finish_place: place}
        else
          entry
        end
      end)
    end)
  end

  # Format racers for the API
  defp format_racers_for_api(racers) do
    Enum.map(racers, fn racer ->
      %{
        "racer_id" => racer.racer_id,
        "first_name" => racer.first_name,
        "last_name" => racer.last_name,
        "car_number" => racer.car_number,
        "car_name" => racer.car_name,
        "group" => racer.group,
        "rank" => racer.rank
      }
    end)
  end

  # Format racer_heats for the API
  defp format_racer_heats_for_api(racer_heats) do
    Enum.map(racer_heats, fn rh ->
      %{
        "result_id" => rh.result_id,
        "racer_id" => rh.racer_id,
        "heat_number" => rh.heat_number,
        "lane_number" => rh.lane_number,
        "car_number" => rh.car_number,
        "group" => rh.group,
        "finish_seconds" => rh.finish_seconds,
        "finish_place" => rh.finish_place,
        "finished_at_unix" => rh.finished_at_unix
      }
    end)
  end

  @doc """
  Writes snapshots to a JSON file.
  """
  def write_snapshots(snapshots, output_path) do
    json = Jason.encode!(snapshots, pretty: true)
    File.write!(output_path, json)
    :ok
  end

  @doc """
  Reads snapshots from a JSON file.
  """
  def read_snapshots(input_path) do
    case File.read(input_path) do
      {:ok, content} ->
        Jason.decode(content)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
