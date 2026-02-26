import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# temporary runtime configuration

if System.get_env("PHX_SERVER") do
  config :cyanea, CyaneaWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_path = System.get_env("DATABASE_PATH") || "/data/cyanea.db"

  config :cyanea, Cyanea.Repo,
    database: database_path

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "cyanea.dev"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :cyanea, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :cyanea, CyaneaWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Guardian secret
  config :cyanea, Cyanea.Guardian,
    secret_key: System.get_env("GUARDIAN_SECRET_KEY") || secret_key_base

  # S3 configuration
  config :ex_aws,
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
    region: System.get_env("AWS_REGION") || "us-east-1"

  if s3_endpoint = System.get_env("S3_ENDPOINT") do
    config :ex_aws, :s3,
      scheme: "https://",
      host: s3_endpoint
  end

  # Meilisearch configuration
  config :meilisearch,
    endpoint: System.get_env("MEILISEARCH_URL") || "http://localhost:7700",
    api_key: System.get_env("MEILISEARCH_API_KEY")

  config :cyanea, :search_enabled, true

  # ORCID OAuth configuration
  config :ueberauth, Ueberauth.Strategy.Orcid.OAuth,
    client_id: System.get_env("ORCID_CLIENT_ID"),
    client_secret: System.get_env("ORCID_CLIENT_SECRET")

  # Stripe configuration
  config :stripity_stripe,
    api_key: System.get_env("STRIPE_SECRET_KEY"),
    signing_secret: System.get_env("STRIPE_WEBHOOK_SECRET")

  config :cyanea, :stripe_prices,
    pro_monthly_user: System.get_env("STRIPE_PRICE_PRO_USER"),
    pro_monthly_org: System.get_env("STRIPE_PRICE_PRO_ORG")

  # Mailer configuration
  if smtp_host = System.get_env("SMTP_HOST") do
    config :cyanea, Cyanea.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: smtp_host,
      port: String.to_integer(System.get_env("SMTP_PORT") || "587"),
      username: System.get_env("SMTP_USERNAME"),
      password: System.get_env("SMTP_PASSWORD"),
      tls: :if_available,
      auth: :if_available
  end

  if mailer_from = System.get_env("MAILER_FROM_ADDRESS") do
    config :cyanea, :mailer_from,
      {System.get_env("MAILER_FROM_NAME") || "Cyanea", mailer_from}
  end

  # DataCite DOI minting (optional)
  if datacite_prefix = System.get_env("DATACITE_PREFIX") do
    config :cyanea, :datacite,
      prefix: datacite_prefix,
      api_url: System.get_env("DATACITE_API_URL") || "https://api.datacite.org",
      username: System.get_env("DATACITE_USERNAME"),
      password: System.get_env("DATACITE_PASSWORD")
  end
end
