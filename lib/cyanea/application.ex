defmodule Cyanea.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CyaneaWeb.Telemetry,
      Cyanea.Repo,
      {DNSCluster, query: Application.get_env(:cyanea, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Cyanea.PubSub},
      {Finch, name: Cyanea.Finch},
      {Oban, Application.fetch_env!(:cyanea, Oban)},
      CyaneaWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Cyanea.Supervisor]
    result = Supervisor.start_link(children, opts)

    # Run startup tasks (S3 bucket, search indexes) after supervisor is up
    Task.start(fn -> run_startup_tasks() end)

    result
  end

  defp run_startup_tasks do
    if Application.get_env(:cyanea, :ensure_s3_bucket) do
      try do
        Cyanea.Storage.ensure_bucket!()
      rescue
        e -> require Logger; Logger.warning("Failed to ensure S3 bucket: #{inspect(e)}")
      end
    end

    if Application.get_env(:cyanea, :search_enabled, false) do
      try do
        Cyanea.Search.setup_indexes()
      rescue
        e -> require Logger; Logger.warning("Failed to setup search indexes: #{inspect(e)}")
      end
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    CyaneaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
