defmodule DerbyLive.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Swoosh.Email.Recipient, name: :name, address: :email}

  @api_key_length 64
  @auth_token_length 64
  # 15 minutes
  @auth_token_expires_after 60 * 15

  schema "users" do
    field :name, :string
    field :email, :string
    field :auth_token, :string
    field :auth_token_expires_at, :naive_datetime
    field :api_key, :string

    timestamps()
  end

  @doc false
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
    |> unique_constraint(:email)
    |> gen_auth_token()
    |> gen_api_key()
    |> set_auth_token_expires_at()
  end

  def reset_auth_token_changeset(user) do
    user
    |> change()
    |> gen_auth_token()
    |> set_auth_token_expires_at()
  end

  defp gen_api_key(changeset) do
    api_key = gen_secure_token(@api_key_length)

    changeset
    |> put_change(:api_key, api_key)
  end

  defp gen_auth_token(changeset) do
    auth_token = gen_secure_token(@auth_token_length)

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

  defp gen_secure_token(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
