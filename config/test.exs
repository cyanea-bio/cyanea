import Config

# Configure your database
config :cyanea, Cyanea.Repo,
  database: Path.expand("../cyanea_test#{System.get_env("MIX_TEST_PARTITION")}.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test
config :cyanea, CyaneaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_change_in_prod_must_be_at_least_64_bytes_long_for_security",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Disable Oban during tests
config :cyanea, Oban, testing: :manual

# S3 configuration for tests (MinIO)
config :ex_aws,
  access_key_id: "minioadmin",
  secret_access_key: "minioadmin",
  region: "us-east-1"

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9002

config :cyanea, :s3_bucket, "cyanea-test"
config :cyanea, :ensure_s3_bucket, true

# Disable search in tests
config :cyanea, :search_enabled, false

# ORCID OAuth dummy config for tests
config :ueberauth, Ueberauth.Strategy.Orcid.OAuth,
  client_id: "test-client-id",
  client_secret: "test-client-secret"

# Stripe test config
config :stripity_stripe,
  api_key: "sk_test_fake_key",
  signing_secret: "whsec_test_fake_secret"

config :cyanea, :stripe_prices,
  pro_monthly_user: "price_test_pro_user",
  pro_monthly_org: "price_test_pro_org"

# Swoosh test adapter (no emails sent, captures for assertions)
config :cyanea, Cyanea.Mailer, adapter: Swoosh.Adapters.Test

# Disable rate limiting in tests
config :cyanea, :rate_limit_enabled, false
