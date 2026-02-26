import Config

# General application configuration
config :cyanea,
  ecto_repos: [Cyanea.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :cyanea, CyaneaWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: CyaneaWeb.ErrorHTML, json: CyaneaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Cyanea.PubSub,
  live_view: [signing_salt: "cyanea_lv_salt"]

# Configure esbuild
config :esbuild,
  version: "0.23.1",
  cyanea: [
    args: ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind
config :tailwind,
  version: "3.4.14",
  cyanea: [
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

# Use Jason for JSON parsing
config :phoenix, :json_library, Jason

# Oban configuration
config :cyanea, Oban,
  repo: Cyanea.Repo,
  queues: [
    default: 10,
    uploads: 5,
    analysis: 3,
    exports: 2,
    compliance: 5,
    federation: 5
  ],
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       {"0 * * * *", Cyanea.Workers.StorageRecalcWorker},
       {"*/15 * * * *", Cyanea.Workers.NodeHealthWorker},
       {"*/5 * * * *", Cyanea.Workers.SyncRetryWorker}
     ]}
  ]

# S3 bucket
config :cyanea, :s3_bucket, "cyanea-dev"

# Ueberauth OAuth providers
config :ueberauth, Ueberauth,
  providers: [
    orcid: {Ueberauth.Strategy.Orcid, []}
  ]

# Guardian configuration
config :cyanea, Cyanea.Guardian,
  issuer: "cyanea",
  secret_key: "dev_secret_key_change_in_prod"

# Stripe configuration
config :stripity_stripe,
  api_key: "sk_test_placeholder",
  signing_secret: "whsec_placeholder"

# DataCite DOI minting (disabled by default)
config :cyanea, :datacite,
  prefix: nil,
  api_url: nil,
  username: nil,
  password: nil

# Import environment specific config
import_config "#{config_env()}.exs"
