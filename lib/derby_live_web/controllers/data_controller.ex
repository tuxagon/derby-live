defmodule DerbyLiveWeb.DataController do
  use DerbyLiveWeb, :controller

  alias DerbyLive.Importer

  def import(conn, %{"racers" => racers}) do
    Importer.import_racers(racers)
    json(conn, %{status: "ok"})
  end

  def import(conn, %{"racer_heats" => racer_heats}) do
    Importer.import_racer_heats(racer_heats)
    json(conn, %{status: "ok"})
  end
end
