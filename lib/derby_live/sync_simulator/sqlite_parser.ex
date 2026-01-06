defmodule DerbyLive.SyncSimulator.SqliteParser do
  @moduledoc """
  Parses SQLite databases from derby timing software to extract race structure.

  This module reads the SQLite database format used by pinewood derby timing
  software (e.g., GrandPrix Race Manager) and extracts:
  - Racer count and rank distribution
  - Heat schedule structure
  - Lane configuration

  Note: This extracts STRUCTURE only, not actual racer names (for privacy).
  """

  @doc """
  Opens a SQLite database and extracts the race structure.

  Returns a map with:
  - `:ranks` - List of {rank_name, racer_count} tuples
  - `:heats` - List of heat info maps
  - `:lane_count` - Maximum number of lanes
  - `:class_name` - The class name (e.g., "Cubs")
  """
  def parse(db_path) do
    {:ok, conn} = Exqlite.Sqlite3.open(db_path, mode: :readonly)

    try do
      ranks = extract_ranks(conn)
      heats = extract_heats(conn)
      lane_count = extract_lane_count(conn)
      class_name = extract_class_name(conn)

      {:ok,
       %{
         ranks: ranks,
         heats: heats,
         lane_count: lane_count,
         class_name: class_name
       }}
    after
      Exqlite.Sqlite3.close(conn)
    end
  end

  @doc """
  Extracts rank distribution from the database.

  Returns a list of maps: [%{rank: "Tigers", count: 5}, ...]
  """
  def extract_ranks(conn) do
    query = """
    SELECT Rank, COUNT(*) as count
    FROM qryRoster
    GROUP BY Rank
    ORDER BY Rank
    """

    rows = query_all(conn, query)

    Enum.map(rows, fn [rank, count] ->
      %{rank: rank, count: count}
    end)
  end

  @doc """
  Extracts heat structure from the RaceChart table.

  Returns a list of maps containing heat info:
  [%{heat_number: 1, lane_assignments: [{lane: 1, racer_id: 5}, ...]}, ...]
  """
  def extract_heats(conn) do
    query = """
    SELECT rc.Heat as heat_number,
           rc.Lane as lane_number,
           rc.RacerID as racer_id,
           rc.ResultID as result_id,
           ri.CarNumber as car_number,
           c.Class as class_name,
           rk.Rank as rank_name,
           rc.FinishTime as finish_time,
           rc.FinishPlace as finish_place,
           rc.Completed as completed_at
    FROM RaceChart rc
    INNER JOIN RegistrationInfo ri ON rc.RacerID = ri.RacerID
    INNER JOIN Classes c ON c.ClassID = rc.ClassID
    INNER JOIN Ranks rk ON rk.RankID = ri.RankID
    ORDER BY rc.Heat, rc.Lane
    """

    rows = query_all(conn, query)

    rows
    |> Enum.map(fn [
                     heat_number,
                     lane_number,
                     racer_id,
                     result_id,
                     car_number,
                     class_name,
                     rank_name,
                     finish_time,
                     finish_place,
                     completed_at
                   ] ->
      %{
        heat_number: heat_number,
        lane_number: lane_number,
        racer_id: racer_id,
        result_id: result_id,
        car_number: car_number,
        class_name: class_name,
        rank_name: rank_name,
        finish_time: finish_time,
        finish_place: finish_place,
        completed_at: completed_at
      }
    end)
    |> Enum.group_by(& &1.heat_number)
    |> Enum.map(fn {heat_number, lanes} ->
      %{
        heat_number: heat_number,
        lanes:
          Enum.map(lanes, fn lane ->
            %{
              lane_number: lane.lane_number,
              racer_id: lane.racer_id,
              result_id: lane.result_id,
              car_number: lane.car_number,
              class_name: lane.class_name,
              rank_name: lane.rank_name,
              finish_time: lane.finish_time,
              finish_place: lane.finish_place,
              completed_at: lane.completed_at
            }
          end)
      }
    end)
    |> Enum.sort_by(& &1.heat_number)
  end

  @doc """
  Extracts the maximum lane count from the database.
  """
  def extract_lane_count(conn) do
    [[max_lane]] = query_all(conn, "SELECT MAX(Lane) FROM RaceChart")
    max_lane || 4
  end

  @doc """
  Extracts the class name (e.g., "Cubs") from the database.
  """
  def extract_class_name(conn) do
    case query_all(conn, "SELECT Class FROM Classes LIMIT 1") do
      [[class_name]] -> class_name
      _ -> "Cubs"
    end
  end

  @doc """
  Extracts unique racers from the database.

  Returns a list of maps with racer structure (without real names):
  [%{racer_id: 1, car_number: 12, rank: "Tigers"}, ...]
  """
  def extract_racers(conn) do
    query = """
    SELECT RacerID, CarNumber, Rank, Class
    FROM qryRoster
    ORDER BY RacerID
    """

    rows = query_all(conn, query)

    Enum.map(rows, fn [racer_id, car_number, rank, class] ->
      %{
        racer_id: racer_id,
        car_number: car_number,
        rank: rank,
        group: class
      }
    end)
  end

  # Helper to run a query and fetch all results
  defp query_all(conn, sql) do
    {:ok, stmt} = Exqlite.Sqlite3.prepare(conn, sql)
    {:ok, rows} = Exqlite.Sqlite3.fetch_all(conn, stmt)
    :ok = Exqlite.Sqlite3.release(conn, stmt)
    rows
  end
end
