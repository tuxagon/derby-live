defmodule DerbyLive.Racing.RacerHeat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "racer_heats" do
    field :group, :string
    field :racer_id, :integer
    field :heat_number, :integer
    field :lane_number, :integer
    field :car_number, :integer
    field :finish_seconds, :float
    field :finish_place, :integer
    field :finished_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(racer_heat, attrs) do
    racer_heat
    |> cast(attrs, [
      :racer_id,
      :group,
      :heat_number,
      :lane_number,
      :car_number,
      :finish_seconds,
      :finish_place,
      :finished_at
    ])
    |> validate_required([:racer_id, :group, :heat_number, :lane_number, :car_number])
  end

  def importable_fields do
    [
      "racer_id",
      "group",
      "heat_number",
      "lane_number",
      "car_number",
      "finish_seconds",
      "finish_place",
      "finished_at"
    ]
  end
end
