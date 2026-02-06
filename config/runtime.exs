import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# temporary runtime configuration

if System.get_env("PHX_SERVER") do
  config :cyanea, CyaneaWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :cyanea, Cyanea.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

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
end
