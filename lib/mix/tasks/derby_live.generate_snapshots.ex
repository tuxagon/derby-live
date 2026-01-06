defmodule Mix.Tasks.DerbyLive.GenerateSnapshots do
  @moduledoc """
  Generates synthetic derby race snapshots from a SQLite database.

  This task reads the structure of a real derby database (heat schedule,
  racer count, rank distribution) and generates fake data with synthetic
  names to protect student privacy.

  ## Usage

      mix derby_live.generate_snapshots <sqlite_path> <output_path>

  ## Arguments

    * `sqlite_path` - Path to the SQLite database from derby timing software
    * `output_path` - Path where the JSON snapshots will be written

  ## Options

    * `--min-time` - Minimum finish time in seconds (default: 2.5)
    * `--max-time` - Maximum finish time in seconds (default: 4.0)

  ## Examples

      # Generate from 2024 database
      $ mix derby_live.generate_snapshots tmp/2024PinewoodDerby.sqlite tmp/snapshots.json

      # Generate with custom time range
      $ mix derby_live.generate_snapshots tmp/derby.sqlite tmp/snapshots.json --min-time 2.0 --max-time 5.0

  ## Output

  The output is a JSON file containing a list of snapshots. Each snapshot
  represents the state of the race after one more heat has completed:

  - Snapshot 0: All racers registered, all heats scheduled (no results)
  - Snapshot 1: Heat 1 completed with times and places
  - Snapshot N: Heats 1-N completed
  - Final snapshot: All heats completed

  Each snapshot has the format expected by the `/api/data` endpoint:

      {
        "racers": [...],
        "racer_heats": [...]
      }
  """
  use Mix.Task

  alias DerbyLive.SyncSimulator.Generator

  @shortdoc "Generates synthetic derby race snapshots from SQLite"

  @switches [
    min_time: :float,
    max_time: :float
  ]

  @impl Mix.Task
  def run(args) do
    {opts, positional, _invalid} = OptionParser.parse(args, switches: @switches)

    case positional do
      [sqlite_path, output_path] ->
        generate(sqlite_path, output_path, opts)

      _ ->
        print_usage()
    end
  end

  defp generate(sqlite_path, output_path, opts) do
    unless File.exists?(sqlite_path) do
      Mix.shell().error("Error: SQLite file not found: #{sqlite_path}")
      System.halt(1)
    end

    Mix.shell().info("Parsing SQLite database: #{sqlite_path}")

    generator_opts = [
      min_time: Keyword.get(opts, :min_time, 2.5),
      max_time: Keyword.get(opts, :max_time, 4.0)
    ]

    {:ok, snapshots} = Generator.generate_from_sqlite(sqlite_path, generator_opts)

    snapshot_count = length(snapshots)
    heat_count = snapshot_count - 1

    # Count racers and heats from first snapshot
    first_snapshot = List.first(snapshots)
    racer_count = length(first_snapshot.racers)
    racer_heat_count = length(first_snapshot.racer_heats)

    Mix.shell().info("Generated #{snapshot_count} snapshots:")
    Mix.shell().info("  - #{racer_count} racers with fake names")
    Mix.shell().info("  - #{heat_count} heats")
    Mix.shell().info("  - #{racer_heat_count} racer heat entries")

    Generator.write_snapshots(snapshots, output_path)
    Mix.shell().info("Wrote snapshots to: #{output_path}")

    # Show sample of generated data
    sample_racer = List.first(first_snapshot.racers)
    Mix.shell().info("")
    Mix.shell().info("Sample racer:")
    Mix.shell().info("  #{sample_racer["first_name"]} #{sample_racer["last_name"]}")
    Mix.shell().info("  Car ##{sample_racer["car_number"]}")
    Mix.shell().info("  Rank: #{sample_racer["rank"]}")
  end

  defp print_usage do
    Mix.shell().error("Usage: mix derby_live.generate_snapshots <sqlite_path> <output_path>")
    Mix.shell().error("")
    Mix.shell().error("Options:")
    Mix.shell().error("  --min-time  Minimum finish time in seconds (default: 2.5)")
    Mix.shell().error("  --max-time  Maximum finish time in seconds (default: 4.0)")
    Mix.shell().error("")
    Mix.shell().error("Example:")

    Mix.shell().error(
      "  mix derby_live.generate_snapshots tmp/2024PinewoodDerby.sqlite tmp/snapshots.json"
    )
  end
end
