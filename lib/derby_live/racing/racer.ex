defmodule DerbyLive.Racing.Racer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "racers" do
    field :racer_id, :integer
    field :group, :string
    field :first_name, :string
    field :last_name, :string
    field :rank, :string
    field :car_name, :string
    field :car_number, :integer

    timestamps()
  end

  @doc false
  def changeset(racer, attrs) do
    racer
    |> cast(attrs, [:racer_id, :first_name, :last_name, :rank, :group, :car_name, :car_number])
    |> validate_required([:racer_id, :first_name, :last_name, :rank, :group, :car_number])
  end

  def importable_fields do
    ["racer_id", "first_name", "last_name", "rank", "group", "car_name", "car_number"]
  end
end
