defmodule DerbyLive.Racing do
  alias DerbyLive.Repo
  alias DerbyLive.Racing.Racer
  alias DerbyLive.Racing.RacerHeat

  def list_racers do
    Repo.all(Racer)
  end

  def get_racer!(id) do
    Repo.get!(Racer, id)
  end

  def create_racer(attrs \\ %{}) do
    %Racer{}
    |> Racer.changeset(attrs)
    |> Repo.insert()
  end

  def update_racer(racer, attrs) do
    racer
    |> Racer.changeset(attrs)
    |> Repo.update()
  end

  def delete_racer(racer) do
    Repo.delete(racer)
  end

  def list_racer_heats do
    Repo.all(RacerHeat)
  end

  def get_racer_heat!(id) do
    Repo.get!(RacerHeat, id)
  end

  def create_racer_heat(attrs \\ %{}) do
    %RacerHeat{}
    |> RacerHeat.changeset(attrs)
    |> Repo.insert()
  end

  def update_racer_heat(racer_heat, attrs) do
    racer_heat
    |> RacerHeat.changeset(attrs)
    |> Repo.update()
  end

  def delete_racer_heat(racer_heat) do
    Repo.delete(racer_heat)
  end
end
