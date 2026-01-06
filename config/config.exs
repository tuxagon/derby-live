# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :derby_live,
  ecto_repos: [DerbyLive.Repo],
  ash_domains: [DerbyLive.Accounts, DerbyLive.Racing]

# Ash configuration
config :ash,
  include_embedded_source_by_default?: false,
  default_page_type: :keyset,
  policies: [no_filter_static_forbidden_reads?: false]

# Token signing secret for AshAuthentication
config :derby_live, :token_signing_secret, "super_secret_key_change_in_prod"

# Configures the endpoint
config :derby_live, DerbyLiveWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: DerbyLiveWeb.ErrorHTML, json: DerbyLiveWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DerbyLive.PubSub,
  live_view: [signing_salt: "Q+A3ELTN"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :derby_live, DerbyLive.Mailer,
  adapter: Swoosh.Adapters.Local,
  sender: %{name: "Derby Live", email: "noreply@example.com"}

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
