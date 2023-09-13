defmodule DerbyLive.Racing.Heat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "heats" do
    field :group, :string
    field :racer_id, :integer
    field :rank, :string
    field :heat_number, :integer
    field :lane_number, :integer
    field :car_number, :integer
    field :finish_seconds, :float
    field :finish_place, :integer
    field :finished_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(heat, attrs) do
    heat
    |> cast(attrs, [
      :racer_id,
      :group,
      :rank,
      :heat_number,
      :lane_number,
      :car_number,
      :finish_seconds,
      :finish_place,
      :finished_at
    ])
    |> validate_required([:racer_id, :group, :rank, :heat_number, :lane_number, :car_number])
  end
end
