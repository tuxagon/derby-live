defmodule DerbyLive.Accounts.User do
  @moduledoc """
  User resource with magic link authentication.

  This resource uses AshAuthentication's magic link strategy for passwordless
  email-based authentication. Users receive a time-limited link via email that
  logs them in when clicked.
  """
  use Ash.Resource,
    domain: DerbyLive.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication]

  @derive {Swoosh.Email.Recipient, name: :name, address: :email}

  authentication do
    tokens do
      enabled?(true)
      token_resource(DerbyLive.Accounts.Token)
      require_token_presence_for_authentication?(true)

      signing_secret(fn _, _ ->
        {:ok, Application.get_env(:derby_live, :token_signing_secret)}
      end)
    end

    strategies do
      magic_link do
        identity_field(:email)
        registration_enabled?(false)
        require_interaction?(true)

        sender(fn user_or_email, token, _opts ->
          DerbyLive.Accounts.MagicLinkSender.send(user_or_email, token)
        end)
      end
    end
  end

  postgres do
    table("users")
    repo(DerbyLive.Repo)
  end

  attributes do
    integer_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :email, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :api_key, :string do
      allow_nil?(true)
      public?(false)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  identities do
    identity(:unique_email, [:email])
  end

  actions do
    defaults([:read])

    read :by_email do
      argument(:email, :string, allow_nil?: false)
      get?(true)
      filter(expr(email == ^arg(:email)))
    end

    read :by_api_key do
      argument(:api_key, :string, allow_nil?: false)
      get?(true)
      filter(expr(api_key == ^arg(:api_key)))
    end

    create :register do
      accept([:name, :email])

      change(fn changeset, _context ->
        Ash.Changeset.change_attribute(changeset, :api_key, generate_api_key())
      end)
    end

    update :update do
      accept([:name, :email])
    end

    destroy :destroy do
      primary?(true)
    end
  end

  defp generate_api_key do
    :crypto.strong_rand_bytes(64)
    |> Base.url_encode64()
    |> binary_part(0, 64)
  end
end
