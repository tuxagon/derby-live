defmodule DerbyLiveWeb.DataControllerTest do
  use DerbyLiveWeb.ConnCase

  test "responds with 401 when api key is invalid", %{conn: conn} do
    conn = post(conn, "/api/data", %{"racers" => []})

    assert json_response(conn, 401) == %{"error" => "Invalid API key"}
  end

  test "POST /api/data for racers", %{conn: conn} do
    user = insert_user()
    event = insert_event(%{}, user)

    conn =
      conn
      |> put_req_header("x-api-key", user.api_key)
      |> post("/api/data", %{
        "event_key" => event.key,
        "racers" => [
          %{
            "racer_id" => 1,
            "first_name" => "John",
            "last_name" => "Doe",
            "rank" => "Tigers",
            "group" => "Cubs",
            "car_name" => "The Tiger",
            "car_number" => 101
          }
        ]
      })

    assert json_response(conn, 200) == %{"status" => "ok"}
  end

  test "POST /api/data for racer_heats", %{conn: conn} do
    user = insert_user()
    event = insert_event(%{}, user)

    conn =
      conn
      |> put_req_header("x-api-key", user.api_key)
      |> post("/api/data", %{
        "event_key" => event.key,
        "racer_heats" => [
          %{
            "result_id" => 1,
            "racer_id" => 1,
            "group" => "Cubs",
            "heat_number" => 1,
            "lane_number" => 1,
            "car_number" => 101,
            "finish_seconds" => 2.0,
            "finish_place" => 1,
            "finished_at_unix" => 1_644_678_240
          }
        ]
      })

    assert json_response(conn, 200) == %{"status" => "ok"}
  end

  test "POST /api/data for invalid event key", %{conn: conn} do
    user = insert_user()

    conn =
      conn
      |> put_req_header("x-api-key", user.api_key)
      |> post("/api/data", %{
        "event_key" => "invalid",
        "racers" => [
          %{
            "racer_id" => 1,
            "first_name" => "John",
            "last_name" => "Doe",
            "rank" => "Tigers",
            "group" => "Cubs",
            "car_name" => "The Tiger",
            "car_number" => 101
          }
        ]
      })

    assert json_response(conn, 200) == %{"status" => "error", "message" => "Invalid event key"}
  end
end
