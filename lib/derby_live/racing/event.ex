defmodule DerbyLive.Racing.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @url_prefix_length 24

  schema "events" do
    field :name, :string
    field :status, :string
    field :url_prefix, :string

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
    |> gen_url_prefix
  end

  # generate alphanumeric url prefix
  defp gen_url_prefix(changeset) do
    url_prefix =
      :crypto.strong_rand_bytes(@url_prefix_length)
      |> Base.url_encode64(padding: false)

    put_change(changeset, :url_prefix, url_prefix)
  end
end
