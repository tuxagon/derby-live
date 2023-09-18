defmodule DerbyLive.Racing.Racer do
  use Ecto.Schema
  import Ecto.Changeset

  alias DerbyLive.Racing.Event

  schema "racers" do
    field :racer_id, :integer
    field :group, :string
    field :first_name, :string
    field :last_name, :string
    field :rank, :string
    field :car_name, :string
    field :car_number, :integer

    belongs_to :event, Event

    timestamps()
  end

  @doc false
  def changeset(racer, attrs) do
    racer
    |> cast(attrs, [
      :racer_id,
      :first_name,
      :last_name,
      :rank,
      :group,
      :car_name,
      :car_number,
      :event_id
    ])
    |> validate_required([
      :racer_id,
      :first_name,
      :last_name,
      :rank,
      :group,
      :car_number,
      :event_id
    ])
    |> assoc_constraint(:event)
  end

  def importable_fields do
    ["racer_id", "first_name", "last_name", "rank", "group", "car_name", "car_number"]
  end
end
