import Config

# Configure your database
config :cyanea, Cyanea.Repo,
  database: Path.expand("../cyanea_dev.db", __DIR__),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

# For development, we disable any cache and enable debugging
config :cyanea, CyaneaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base_change_in_prod_must_be_at_least_64_bytes_long_for_security",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:cyanea, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:cyanea, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading
config :cyanea, CyaneaWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/cyanea_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :cyanea, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# S3 configuration for local development (MinIO)
config :ex_aws,
  access_key_id: "minioadmin",
  secret_access_key: "minioadmin",
  region: "us-east-1"

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9002

# ORCID OAuth sandbox
config :ueberauth, Ueberauth.Strategy.Orcid.OAuth,
  client_id: "APP-XXXXXXXXXXXXXXXX",
  client_secret: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  site: "https://sandbox.orcid.org"

# Meilisearch for local development
config :meilisearch,
  endpoint: "http://localhost:7700",
  api_key: "dev_master_key"

config :cyanea, :search_enabled, true

# Stripe test mode
config :stripity_stripe,
  api_key: System.get_env("STRIPE_SECRET_KEY") || "sk_test_placeholder",
  signing_secret: System.get_env("STRIPE_WEBHOOK_SECRET") || "whsec_placeholder"

config :cyanea, :stripe_prices,
  pro_monthly_user: System.get_env("STRIPE_PRICE_PRO_USER") || "price_test_pro_user",
  pro_monthly_org: System.get_env("STRIPE_PRICE_PRO_ORG") || "price_test_pro_org"

# Swoosh local mailbox for development
config :cyanea, Cyanea.Mailer, adapter: Swoosh.Adapters.Local

# Disable Oban in test
config :cyanea, Oban, testing: :inline
