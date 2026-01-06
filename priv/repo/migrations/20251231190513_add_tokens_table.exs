defmodule DerbyLive.Repo.Migrations.AddTokensTable do
  @moduledoc """
  Creates the tokens table for AshAuthentication.
  """

  use Ecto.Migration

  def up do
    create table(:tokens, primary_key: false) do
      add :jti, :text, null: false, primary_key: true
      add :subject, :text, null: false
      add :purpose, :text, null: false
      add :expires_at, :utc_datetime, null: false
      add :extra_data, :map

      add :created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    # Add indexes for racer_heats and racers on event_id if not exists
    # (These support the new Ash-based queries)
    create_if_not_exists index(:racers, [:event_id])
    create_if_not_exists index(:racer_heats, [:event_id])

    # Add unique index for racer_event identity if not exists
    create_if_not_exists unique_index(:racers, [:racer_id, :event_id],
                           name: "racers_racer_event_index"
                         )

    # Add unique index for result_event identity if not exists
    create_if_not_exists unique_index(:racer_heats, [:result_id, :event_id],
                           name: "racer_heats_result_event_index"
                         )
  end

  def down do
    drop_if_exists unique_index(:racer_heats, [:result_id, :event_id],
                     name: "racer_heats_result_event_index"
                   )

    drop_if_exists unique_index(:racers, [:racer_id, :event_id], name: "racers_racer_event_index")
    drop_if_exists index(:racer_heats, [:event_id])
    drop_if_exists index(:racers, [:event_id])
    drop table(:tokens)
  end
end
