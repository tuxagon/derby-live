defmodule DerbyLive.Racing.Event do
  use Ecto.Schema
  import Ecto.Changeset

  alias DerbyLive.Account.User

  @key_length 24

  schema "events" do
    field :name, :string
    field :status, :string, default: "live"
    field :key, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def update_changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :status])
    |> validate_required([:name, :status])
  end

  def create_changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :status, :user_id])
    |> validate_required([:name, :status, :user_id])
    |> validate_inclusion(:status, ["live", "archived"])
    |> unique_constraint(:key)
    |> assoc_constraint(:user)
    |> gen_key()
  end

  # generate alphanumeric url prefix
  defp gen_key(changeset) do
    key =
      :crypto.strong_rand_bytes(@key_length)
      |> Base.url_encode64(padding: false)

    put_change(changeset, :key, key)
  end
end
