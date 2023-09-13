defmodule DerbyLive.Racing do
  alias DerbyLive.Repo
  alias DerbyLive.Racing.Racer
  alias DerbyLive.Racing.Heat

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

  def list_heats do
    Repo.all(Heat)
  end

  def get_heat!(id) do
    Repo.get!(Heat, id)
  end

  def create_heat(attrs \\ %{}) do
    %Heat{}
    |> Heat.changeset(attrs)
    |> Repo.insert()
  end

  def update_heat(heat, attrs) do
    heat
    |> Heat.changeset(attrs)
    |> Repo.update()
  end

  def delete_heat(heat) do
    Repo.delete(heat)
  end
end
