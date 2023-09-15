defmodule DerbyLive.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Swoosh.Email.Recipient, name: :name, address: :email}

  @auth_token_length 64
  # 15 minutes
  @auth_token_expires_after 60 * 15

  schema "users" do
    field :name, :string
    field :email, :string
    field :auth_token, :string
    field :auth_token_expires_at, :naive_datetime

    timestamps()
  end

  @doc false
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :auth_token, :auth_token_expires_at])
    |> validate_required([:name, :email])
    |> unique_constraint(:email)
    |> gen_auth_token()
    |> set_auth_token_expires_at()
  end

  def reset_auth_token_changeset(user) do
    user
    |> change()
    |> gen_auth_token()
    |> set_auth_token_expires_at()
  end

  defp gen_auth_token(changeset) do
    auth_token =
      @auth_token_length
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64()
      |> binary_part(0, @auth_token_length)

    changeset
    |> put_change(:auth_token, auth_token)
  end

  defp set_auth_token_expires_at(changeset) do
    expires_at =
      DateTime.utc_now()
      |> DateTime.add(@auth_token_expires_after)
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)

    changeset
    |> put_change(:auth_token_expires_at, expires_at)
  end
end
