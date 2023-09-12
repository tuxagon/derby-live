defmodule DerbyLive.Racing do
  alias DerbyLive.Repo
  alias DerbyLive.Racing.Racer

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
end
