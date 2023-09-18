defmodule DerbyLive.Racing.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @key_length 24

  schema "events" do
    field :name, :string
    field :status, :string
    field :key, :string

    timestamps()
  end

  @doc false
  def live_changeset(event, attrs) do
    event
    |> create_changeset(Enum.into(attrs, %{"status" => "live"}))
  end

  def archived_changeset(event) do
    event
    |> update_changeset(%{"status" => "archived"})
  end

  def update_changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :status])
    |> validate_required([:name, :status])
  end

  defp create_changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :status])
    |> validate_required([:name, :status])
    |> validate_inclusion(:status, ["live", "archived"])
    |> gen_key
  end

  # generate alphanumeric url prefix
  defp gen_key(changeset) do
    key =
      :crypto.strong_rand_bytes(@key_length)
      |> Base.url_encode64(padding: false)

    put_change(changeset, :key, key)
  end
end
