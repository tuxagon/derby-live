defmodule DerbyLive.Racing.RacerHeat do
  @moduledoc """
  RacerHeat resource representing a racer's result in a specific heat.

  This captures timing data from the derby track, including finish times
  and placements for each lane assignment.
  """
  use Ash.Resource,
    domain: DerbyLive.Racing,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("racer_heats")
    repo(DerbyLive.Repo)
  end

  attributes do
    integer_primary_key(:id)

    attribute :result_id, :integer do
      allow_nil?(false)
      public?(true)
      description("External result ID from the timing system")
    end

    attribute :racer_id, :integer do
      allow_nil?(false)
      public?(true)
      description("References the racer's external ID")
    end

    attribute :group, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :heat_number, :integer do
      allow_nil?(false)
      public?(true)
    end

    attribute :lane_number, :integer do
      allow_nil?(false)
      public?(true)
    end

    attribute :car_number, :integer do
      allow_nil?(false)
      public?(true)
    end

    attribute :finish_seconds, :float do
      allow_nil?(true)
      public?(true)
    end

    attribute :finish_place, :integer do
      allow_nil?(true)
      public?(true)
    end

    attribute :finished_at, :naive_datetime do
      allow_nil?(true)
      public?(true)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :event, DerbyLive.Racing.Event do
      allow_nil?(false)
      attribute_type(:integer)
    end
  end

  actions do
    defaults([:read, :destroy])

    read :for_event do
      argument(:event_id, :integer, allow_nil?: false)
      filter(expr(event_id == ^arg(:event_id)))
      prepare(build(sort: [heat_number: :asc, lane_number: :asc]))
    end

    read :by_result_id_and_event do
      argument(:result_id, :integer, allow_nil?: false)
      argument(:event_id, :integer, allow_nil?: false)
      get?(true)
      filter(expr(result_id == ^arg(:result_id) and event_id == ^arg(:event_id)))
    end

    create :create do
      accept([
        :result_id,
        :racer_id,
        :group,
        :heat_number,
        :lane_number,
        :car_number,
        :finish_seconds,
        :finish_place,
        :finished_at
      ])

      argument(:event_id, :integer, allow_nil?: false)
      change(set_attribute(:event_id, arg(:event_id)))
    end

    update :update do
      accept([
        :result_id,
        :racer_id,
        :group,
        :heat_number,
        :lane_number,
        :car_number,
        :finish_seconds,
        :finish_place,
        :finished_at
      ])
    end

    create :upsert do
      description("Create or update a racer heat by result_id and event_id")

      accept([
        :result_id,
        :racer_id,
        :group,
        :heat_number,
        :lane_number,
        :car_number,
        :finish_seconds,
        :finish_place,
        :finished_at
      ])

      argument(:event_id, :integer, allow_nil?: false)
      change(set_attribute(:event_id, arg(:event_id)))
      upsert?(true)
      upsert_identity(:result_event)
    end

    destroy :delete_for_event do
      argument(:event_id, :integer, allow_nil?: false)
    end
  end

  identities do
    identity(:result_event, [:result_id, :event_id])
  end

  @doc """
  List of fields that can be imported from external timing systems.
  """
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
