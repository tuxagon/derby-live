defmodule DerbyLive.Racing.Event do
  @moduledoc """
  Event resource representing a derby racing event.

  Events are owned by users and contain racers and heat results.
  Each event has a unique key used for public viewing URLs.
  """
  use Ash.Resource,
    domain: DerbyLive.Racing,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("events")
    repo(DerbyLive.Repo)
  end

  attributes do
    integer_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :status, :string do
      allow_nil?(false)
      default("live")
      public?(true)
    end

    attribute :key, :string do
      allow_nil?(false)
      public?(true)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :user, DerbyLive.Accounts.User do
      allow_nil?(false)
      attribute_type(:integer)
    end

    has_many :racers, DerbyLive.Racing.Racer do
      destination_attribute(:event_id)
    end

    has_many :racer_heats, DerbyLive.Racing.RacerHeat do
      destination_attribute(:event_id)
    end
  end

  identities do
    identity(:unique_key, [:key])
  end

  actions do
    defaults([:read, :destroy])

    read :by_key do
      argument(:key, :string, allow_nil?: false)
      get?(true)
      filter(expr(key == ^arg(:key)))
    end

    read :for_user do
      argument(:user_id, :integer, allow_nil?: false)
      filter(expr(user_id == ^arg(:user_id)))
      prepare(build(sort: [name: :asc]))
    end

    create :create do
      accept([:name, :status])
      argument(:user_id, :integer, allow_nil?: false)

      change(set_attribute(:user_id, arg(:user_id)))

      change(fn changeset, _context ->
        Ash.Changeset.change_attribute(changeset, :key, generate_key())
      end)
    end

    update :update do
      accept([:name, :status])
    end

    update :archive do
      change(set_attribute(:status, "archived"))
    end
  end

  calculations do
    calculate(:racer_count, :integer, expr(count(racers)))
    calculate(:heat_count, :integer, expr(count(racer_heats, query: [distinct: :heat_number])))
  end

  defp generate_key do
    :crypto.strong_rand_bytes(24)
    |> Base.url_encode64(padding: false)
  end
end
