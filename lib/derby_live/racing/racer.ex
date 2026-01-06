defmodule DerbyLive.Racing.Racer do
  @moduledoc """
  Racer resource representing a participant in a derby event.

  Racers are imported from external timing systems and belong to events.
  Each racer has a unique racer_id within their event.
  """
  use Ash.Resource,
    domain: DerbyLive.Racing,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("racers")
    repo(DerbyLive.Repo)
  end

  attributes do
    integer_primary_key(:id)

    attribute :racer_id, :integer do
      allow_nil?(false)
      public?(true)
      description("External ID from the timing system")
    end

    attribute :group, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :first_name, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :last_name, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :rank, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :car_name, :string do
      allow_nil?(true)
      public?(true)
    end

    attribute :car_number, :integer do
      allow_nil?(false)
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
      prepare(build(sort: [group: :asc, car_number: :asc]))
    end

    read :by_racer_id_and_event do
      argument(:racer_id, :integer, allow_nil?: false)
      argument(:event_id, :integer, allow_nil?: false)
      get?(true)
      filter(expr(racer_id == ^arg(:racer_id) and event_id == ^arg(:event_id)))
    end

    create :create do
      accept([:racer_id, :group, :first_name, :last_name, :rank, :car_name, :car_number])
      argument(:event_id, :integer, allow_nil?: false)
      change(set_attribute(:event_id, arg(:event_id)))
    end

    update :update do
      accept([:racer_id, :group, :first_name, :last_name, :rank, :car_name, :car_number])
    end

    create :upsert do
      description("Create or update a racer by racer_id and event_id")
      accept([:racer_id, :group, :first_name, :last_name, :rank, :car_name, :car_number])
      argument(:event_id, :integer, allow_nil?: false)
      change(set_attribute(:event_id, arg(:event_id)))
      upsert?(true)
      upsert_identity(:racer_event)
    end
  end

  identities do
    identity(:racer_event, [:racer_id, :event_id])
  end

  calculations do
    calculate(:full_name, :string, expr(first_name <> " " <> last_name))
  end

  @doc """
  List of fields that can be imported from external timing systems.
  """
  def importable_fields do
    ["racer_id", "first_name", "last_name", "rank", "group", "car_name", "car_number"]
  end
end
