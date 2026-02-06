import Config

# Configure your database
config :cyanea, Cyanea.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cyanea_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

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
