defmodule DerbyLiveWeb.DataControllerTest do
  use DerbyLiveWeb.ConnCase

  test "POST /data for racers", %{conn: conn} do
    conn =
      post(conn, "/data", %{
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

  test "POST /data for racer_heats", %{conn: conn} do
    conn =
      post(conn, "/data", %{
        "racer_heats" => [
          %{
            "racer_id" => 1,
            "group" => "Cubs",
            "heat_number" => 1,
            "lane_number" => 1,
            "car_number" => 101,
            "finish_seconds" => 2.0,
            "finish_place" => 1,
            "finished_at" => "2019-01-01 12:00:00"
          }
        ]
      })

    assert json_response(conn, 200) == %{"status" => "ok"}
  end
end
