defmodule DerbyLive.Racing.RacerHeat do
  use Ecto.Schema
  import Ecto.Changeset

  alias DerbyLive.Racing.Event

  schema "racer_heats" do
    field :result_id, :integer
    field :group, :string
    field :racer_id, :integer
    field :heat_number, :integer
    field :lane_number, :integer
    field :car_number, :integer
    field :finish_seconds, :float
    field :finish_place, :integer
    field :finished_at, :naive_datetime

    belongs_to :event, Event

    timestamps()
  end

  @doc false
  def changeset(racer_heat, attrs) do
    racer_heat
    |> cast(attrs, [
      :result_id,
      :racer_id,
      :group,
      :heat_number,
      :lane_number,
      :car_number,
      :finish_seconds,
      :finish_place,
      :finished_at,
      :event_id
    ])
    |> validate_required([
      :result_id,
      :racer_id,
      :group,
      :heat_number,
      :lane_number,
      :car_number,
      :event_id
    ])
  end

  def importable_fields do
    [
      "result_id",
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
