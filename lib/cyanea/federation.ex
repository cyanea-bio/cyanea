defmodule Cyanea.Federation do
  @moduledoc """
  The Federation context — global IDs, manifests, node sync, publishing.

  Manages Cyanea's federation layer: connecting nodes, publishing
  signed manifests, tracking sync state, and coordinating cross-node
  content discovery. Federation is selective per-space and opt-in per-node.

  ## Global ID Scheme

  Resources are identified by URIs of the form:

      cyanea://<host>/<owner>/<space-slug>

  For example:

      cyanea://hub.cyanea.io/lab-x/rna-seq-2024

  Global IDs are stable, human-readable, and encode enough context
  for cross-node resolution.
  """
  import Ecto.Query
  require Logger

  alias Cyanea.Repo
  alias Cyanea.Federation.{Node, Manifest, SyncEntry}
  alias Cyanea.Spaces.Space

  # Maximum retry delay: 1 hour
  @max_retry_delay_seconds 3600

  # ===========================================================================
  # Global IDs
  # ===========================================================================

  @doc """
  Generates a global federation ID for a space.

  Format: `cyanea://<host>/<owner>/<space-slug>`

  The host is read from the `FEDERATION_NODE_URL` environment variable,
  falling back to the configured `PHX_HOST`.
  """
  def generate_global_id(%Space{} = space) do
    host = node_host()
    owner_slug = Cyanea.Spaces.owner_display(space)
    "cyanea://#{host}/#{owner_slug}/#{space.slug}"
  end

  @doc """
  Parses a global ID into its components.

  Returns `{:ok, %{host: host, owner: owner, slug: slug}}`
  or `{:error, :invalid_global_id}`.
  """
  def parse_global_id("cyanea://" <> rest) do
    case String.split(rest, "/", parts: 3) do
      [host, owner, slug] ->
        {:ok, %{host: host, owner: owner, slug: slug}}

      _ ->
        {:error, :invalid_global_id}
    end
  end

  def parse_global_id(_), do: {:error, :invalid_global_id}

  @doc """
  Assigns a global ID to a space and persists it.
  """
  def assign_global_id(%Space{} = space) do
    global_id = generate_global_id(space)

    space
    |> Ecto.Changeset.change(global_id: global_id)
    |> Repo.update()
  end

  @doc """
  Returns true if the given global ID belongs to this node.
  """
  def local_global_id?(global_id) do
    case parse_global_id(global_id) do
      {:ok, %{host: host}} -> host == node_host()
      _ -> false
    end
  end

  # ===========================================================================
  # Node Management
  # ===========================================================================

  @doc """
  Lists all federation nodes.
  """
  def list_nodes(opts \\ []) do
    status_filter = Keyword.get(opts, :status, nil)

    query = from(n in Node, order_by: [asc: n.name])

    query =
      if status_filter do
        from(n in query, where: n.status == ^status_filter)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets a node by ID. Raises if not found.
  """
  def get_node!(id), do: Repo.get!(Node, id)

  @doc """
  Gets a node by ID. Returns nil if not found.
  """
  def get_node(id), do: Repo.get(Node, id)

  @doc """
  Gets a node by its URL.
  """
  def get_node_by_url(url), do: Repo.get_by(Node, url: url)

  @doc """
  Registers a new federation node (initially in `pending` status).
  """
  def register_node(attrs) do
    %Node{}
    |> Node.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Activates a pending node after key exchange / verification.
  """
  def activate_node(%Node{} = node) do
    node
    |> Node.changeset(%{status: "active"})
    |> Repo.update()
  end

  @doc """
  Deactivates a node (e.g. if it becomes unreachable).
  """
  def deactivate_node(%Node{} = node) do
    node
    |> Node.changeset(%{status: "inactive"})
    |> Repo.update()
  end

  @doc """
  Revokes a node's federation access.
  """
  def revoke_node(%Node{} = node) do
    node
    |> Node.changeset(%{status: "revoked"})
    |> Repo.update()
  end

  @doc """
  Records a successful sync timestamp on a node.
  """
  def touch_node_sync(%Node{} = node) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    node
    |> Node.changeset(%{last_sync_at: now})
    |> Repo.update()
  end

  @doc """
  Returns summary stats for a node: total syncs, successes, failures,
  total bytes transferred.
  """
  def node_sync_stats(node_id) do
    stats =
      from(s in SyncEntry,
        where: s.node_id == ^node_id,
        select: %{
          total: count(s.id),
          completed: count(fragment("CASE WHEN ? = 'completed' THEN 1 END", s.status)),
          failed: count(fragment("CASE WHEN ? = 'failed' THEN 1 END", s.status)),
          pending: count(fragment("CASE WHEN ? = 'pending' THEN 1 END", s.status)),
          bytes_transferred: coalesce(sum(s.bytes_transferred), 0)
        }
      )
      |> Repo.one()

    stats || %{total: 0, completed: 0, failed: 0, pending: 0, bytes_transferred: 0}
  end

  # ===========================================================================
  # Publishing
  # ===========================================================================

  @doc """
  Publishes a space to the federation network.

  This is the high-level "one-click publish" operation:
  1. Sets the space's federation_policy to "full" (if not already set)
  2. Assigns a global ID
  3. Creates a manifest with comprehensive payload
  4. Enqueues sync entries for all active nodes

  Returns `{:ok, manifest}` or `{:error, reason}`.
  """
  def publish_space(%Space{} = space, opts \\ []) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:ensure_policy, fn _repo, _changes ->
      if space.federation_policy == "none" do
        space
        |> Ecto.Changeset.change(federation_policy: "full")
        |> Repo.update()
      else
        {:ok, space}
      end
    end)
    |> Ecto.Multi.run(:ensure_global_id, fn _repo, %{ensure_policy: space} ->
      if space.global_id do
        {:ok, space}
      else
        assign_global_id(space)
      end
    end)
    |> Ecto.Multi.run(:manifest, fn _repo, %{ensure_global_id: space} ->
      create_or_update_manifest(space, opts)
    end)
    |> Ecto.Multi.run(:sync_entries, fn _repo, %{ensure_global_id: space, manifest: manifest} ->
      enqueue_push_to_active_nodes(space, manifest)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{manifest: manifest}} -> {:ok, manifest}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  @doc """
  Unpublishes (retracts) a space from the federation network.

  Sets the manifest status to "retracted" with a reason and resets
  the space's federation_policy to "none".
  """
  def unpublish_space(%Space{} = space, reason \\ "retracted by owner") do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:retract_manifest, fn _repo, _changes ->
      case get_active_manifest(space.id) do
        nil -> {:ok, nil}
        manifest ->
          manifest
          |> Manifest.changeset(%{status: "retracted", retracted_reason: reason})
          |> Repo.update()
      end
    end)
    |> Ecto.Multi.run(:reset_policy, fn _repo, _changes ->
      space
      |> Ecto.Changeset.change(federation_policy: "none")
      |> Repo.update()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{reset_policy: space}} -> {:ok, space}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  @doc """
  Updates the federation policy on a space.
  """
  def update_federation_policy(%Space{} = space, policy) when policy in ~w(none selective full) do
    space
    |> Ecto.Changeset.change(federation_policy: policy)
    |> Repo.update()
  end

  @doc """
  Lists all spaces that are published (have an active manifest).
  """
  def list_published_spaces(opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(s in Space,
      join: m in Manifest,
      on: m.space_id == s.id and m.status == "published",
      where: s.federation_policy != "none",
      order_by: [desc: m.inserted_at],
      limit: ^limit,
      select: {s, m}
    )
    |> Repo.all()
  end

  @doc """
  Returns the active (published, non-retracted) manifest for a space.
  """
  def get_active_manifest(space_id) do
    from(m in Manifest,
      where: m.space_id == ^space_id and m.status == "published",
      order_by: [desc: m.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  # ===========================================================================
  # Manifests
  # ===========================================================================

  @doc """
  Publishes a signed manifest for a space.

  This creates a manifest record that attests the space's content hash
  and optionally signs it with the node's key.
  """
  def publish_manifest(%Space{} = space, opts \\ []) do
    node_id = Keyword.get(opts, :node_id)
    signature = Keyword.get(opts, :signature)
    signer_key_id = Keyword.get(opts, :signer_key_id)

    # Ensure the space has a global ID.
    space =
      if space.global_id do
        space
      else
        {:ok, space} = assign_global_id(space)
        space
      end

    content_hash = compute_content_hash(space)
    payload = compute_manifest_payload(space)
    revision_number = current_revision_number(space)

    %Manifest{}
    |> Manifest.changeset(%{
      global_id: space.global_id,
      content_hash: content_hash,
      signature: signature,
      signer_key_id: signer_key_id,
      space_id: space.id,
      node_id: node_id,
      revision_number: revision_number,
      payload: payload
    })
    |> Repo.insert()
  end

  @doc """
  Gets the manifest for a space's global ID.
  """
  def get_manifest_by_global_id(global_id) do
    Repo.get_by(Manifest, global_id: global_id)
    |> case do
      nil -> nil
      manifest -> Repo.preload(manifest, [:space, :node])
    end
  end

  @doc """
  Lists manifests, optionally filtered by node or status.
  """
  def list_manifests(opts \\ []) do
    node_id = Keyword.get(opts, :node_id, nil)
    status = Keyword.get(opts, :status, nil)
    limit = Keyword.get(opts, :limit, 100)

    query =
      from(m in Manifest,
        order_by: [desc: m.inserted_at],
        limit: ^limit,
        preload: [:space]
      )

    query =
      if node_id do
        from(m in query, where: m.node_id == ^node_id)
      else
        query
      end

    query =
      if status do
        from(m in query, where: m.status == ^status)
      else
        query
      end

    Repo.all(query)
  end

  # ===========================================================================
  # Sync
  # ===========================================================================

  @doc """
  Records a sync entry for tracking push/pull operations.
  """
  def record_sync(attrs) do
    %SyncEntry{}
    |> SyncEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Marks a sync entry as completed.
  """
  def complete_sync(%SyncEntry{} = entry, opts \\ []) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    bytes = Keyword.get(opts, :bytes_transferred, 0)

    entry
    |> SyncEntry.changeset(%{
      status: "completed",
      completed_at: now,
      bytes_transferred: bytes
    })
    |> Repo.update()
  end

  @doc """
  Marks a sync entry as failed with an error message.
  If retries remain, schedules the next retry with exponential backoff.
  """
  def fail_sync(%SyncEntry{} = entry, error_message) do
    if entry.retries < entry.max_retries do
      schedule_retry(entry, error_message)
    else
      entry
      |> SyncEntry.changeset(%{status: "failed", error_message: error_message})
      |> Repo.update()
    end
  end

  @doc """
  Lists recent sync entries for a node.
  """
  def list_sync_entries(node_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(s in SyncEntry,
      where: s.node_id == ^node_id,
      order_by: [desc: s.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns pending sync entries for a node (resources that need to be synced).
  """
  def pending_syncs(node_id) do
    from(s in SyncEntry,
      where: s.node_id == ^node_id and s.status == "pending",
      order_by: [asc: s.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns sync entries that are ready to be retried (next_retry_at <= now).
  """
  def retryable_syncs do
    now = DateTime.utc_now()

    from(s in SyncEntry,
      where: s.status == "pending" and not is_nil(s.next_retry_at) and s.next_retry_at <= ^now,
      order_by: [asc: s.next_retry_at],
      preload: [:node]
    )
    |> Repo.all()
  end

  @doc """
  Returns the total bytes synced across all nodes.
  """
  def total_bytes_synced do
    from(s in SyncEntry,
      where: s.status == "completed",
      select: coalesce(sum(s.bytes_transferred), 0)
    )
    |> Repo.one()
    |> to_integer()
  end

  # ===========================================================================
  # Revision Sync
  # ===========================================================================

  @doc """
  Returns revisions for a space created after a given revision number.
  Used for incremental sync — only send revisions the remote doesn't have.
  """
  def revisions_since(space_id, since_number) do
    from(r in Cyanea.Revisions.Revision,
      where: r.space_id == ^space_id and r.number > ^since_number,
      order_by: [asc: r.number],
      preload: [:author]
    )
    |> Repo.all()
  end

  @doc """
  Returns blob IDs referenced by a space that a remote node might need.
  Used for content-addressed blob sync.
  """
  def space_blob_ids(space_id) do
    space_file_blobs =
      from(sf in Cyanea.Blobs.SpaceFile,
        where: sf.space_id == ^space_id,
        select: sf.blob_id
      )
      |> Repo.all()

    dataset_file_blobs =
      from(df in Cyanea.Datasets.DatasetFile,
        join: d in Cyanea.Datasets.Dataset,
        on: df.dataset_id == d.id,
        where: d.space_id == ^space_id,
        select: df.blob_id
      )
      |> Repo.all()

    Enum.uniq(space_file_blobs ++ dataset_file_blobs)
  end

  @doc """
  Returns blob SHA-256 hashes for a space, for comparing which blobs
  a remote node already has.
  """
  def space_blob_hashes(space_id) do
    blob_ids = space_blob_ids(space_id)

    if blob_ids == [] do
      []
    else
      from(b in Cyanea.Blobs.Blob,
        where: b.id in ^blob_ids,
        select: {b.id, b.sha256}
      )
      |> Repo.all()
    end
  end

  # ===========================================================================
  # Node Health
  # ===========================================================================

  @doc """
  Checks if a remote node is reachable by making an HTTP GET to its
  health endpoint. Returns `:ok` or `{:error, reason}`.
  """
  def check_node_health(%Node{url: url}) do
    health_url = String.trim_trailing(url, "/") <> "/api/federation/health"

    case http_get(health_url) do
      {:ok, %{status: status}} when status in 200..299 ->
        :ok

      {:ok, %{status: status}} ->
        {:error, "unhealthy status: #{status}"}

      {:error, reason} ->
        {:error, "unreachable: #{inspect(reason)}"}
    end
  end

  @doc """
  Returns the health status for all active nodes.
  """
  def node_health_summary do
    active_nodes = list_nodes(status: "active")

    Enum.map(active_nodes, fn node ->
      healthy? =
        case node.last_sync_at do
          nil -> false
          dt -> DateTime.diff(DateTime.utc_now(), dt, :minute) < 60
        end

      %{
        id: node.id,
        name: node.name,
        url: node.url,
        last_sync_at: node.last_sync_at,
        healthy: healthy?
      }
    end)
  end

  # ===========================================================================
  # Discovery
  # ===========================================================================

  @doc """
  Returns published manifests from remote nodes (excludes local manifests).
  """
  def list_remote_manifests(opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(m in Manifest,
      where: m.status == "published" and not is_nil(m.node_id),
      order_by: [desc: m.inserted_at],
      limit: ^limit,
      preload: [:node]
    )
    |> Repo.all()
  end

  @doc """
  Searches published manifests by name or global ID.
  """
  def search_manifests(query_string, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    search = "%#{query_string}%"

    from(m in Manifest,
      where:
        m.status == "published" and
          (like(m.global_id, ^search) or
             fragment("json_extract(?, '$.name') LIKE ?", m.payload, ^search)),
      order_by: [desc: m.inserted_at],
      limit: ^limit,
      preload: [:space, :node]
    )
    |> Repo.all()
  end

  @doc """
  Stores a manifest received from a remote node during sync.
  Upserts by global_id — creates if new, updates if existing.
  """
  def receive_remote_manifest(attrs) do
    global_id = attrs[:global_id] || attrs["global_id"]

    case Repo.get_by(Manifest, global_id: global_id) do
      nil ->
        %Manifest{}
        |> Manifest.changeset(attrs)
        |> Repo.insert()

      existing ->
        existing
        |> Manifest.changeset(%{
          content_hash: attrs[:content_hash] || attrs["content_hash"],
          payload: attrs[:payload] || attrs["payload"],
          revision_number: attrs[:revision_number] || attrs["revision_number"],
          status: "published"
        })
        |> Repo.update()
    end
  end

  # ===========================================================================
  # Internal
  # ===========================================================================

  defp node_host do
    System.get_env("FEDERATION_NODE_URL", "")
    |> URI.parse()
    |> Map.get(:host)
    |> case do
      nil -> Application.get_env(:cyanea, CyaneaWeb.Endpoint)[:url][:host] || "localhost"
      host -> host
    end
  end

  defp compute_content_hash(%Space{} = space) do
    # Hash the space's content-relevant data
    data = :erlang.term_to_binary({space.id, space.name, space.description, space.tags})

    :crypto.hash(:sha256, data)
    |> Base.encode16(case: :lower)
  end

  defp compute_manifest_payload(%Space{} = space) do
    payload = %{
      "name" => space.name,
      "description" => space.description,
      "visibility" => space.visibility,
      "license" => space.license,
      "tags" => space.tags || [],
      "owner_type" => space.owner_type,
      "federation_policy" => space.federation_policy
    }

    # Add owner display name
    owner_display = Cyanea.Spaces.owner_display(space)
    Map.put(payload, "owner", owner_display)
  end

  defp current_revision_number(%Space{current_revision_id: nil}), do: nil

  defp current_revision_number(%Space{current_revision_id: rev_id}) do
    case Repo.get(Cyanea.Revisions.Revision, rev_id) do
      nil -> nil
      rev -> rev.number
    end
  end

  defp create_or_update_manifest(%Space{} = space, opts) do
    case get_active_manifest(space.id) do
      nil ->
        publish_manifest(space, opts)

      existing ->
        content_hash = compute_content_hash(space)
        payload = compute_manifest_payload(space)
        revision_number = current_revision_number(space)

        existing
        |> Manifest.changeset(%{
          content_hash: content_hash,
          payload: payload,
          revision_number: revision_number,
          status: "published"
        })
        |> Repo.update()
    end
  end

  defp enqueue_push_to_active_nodes(%Space{} = space, _manifest) do
    active_nodes = list_nodes(status: "active")

    entries =
      Enum.map(active_nodes, fn node ->
        {:ok, entry} =
          record_sync(%{
            direction: "push",
            resource_type: "space",
            resource_id: space.id,
            node_id: node.id
          })

        entry
      end)

    {:ok, entries}
  end

  defp schedule_retry(%SyncEntry{} = entry, error_message) do
    new_retries = entry.retries + 1
    # Exponential backoff: 2^retries * 30 seconds, capped at @max_retry_delay_seconds
    delay = min(:math.pow(2, new_retries) * 30, @max_retry_delay_seconds) |> trunc()
    next_retry = DateTime.utc_now() |> DateTime.add(delay, :second) |> DateTime.truncate(:second)

    entry
    |> SyncEntry.changeset(%{
      status: "pending",
      retries: new_retries,
      next_retry_at: next_retry,
      error_message: error_message
    })
    |> Repo.update()
  end

  defp http_get(url) do
    # Use Finch if available, otherwise fall back to :httpc
    case Application.ensure_all_started(:finch) do
      {:ok, _} ->
        finch_get(url)

      _ ->
        httpc_get(url)
    end
  end

  defp finch_get(url) do
    case Finch.build(:get, url) |> Finch.request(Cyanea.Finch) do
      {:ok, response} -> {:ok, %{status: response.status, body: response.body}}
      {:error, reason} -> {:error, reason}
    end
  rescue
    _ -> httpc_get(url)
  end

  defp httpc_get(url) do
    :httpc.request(:get, {String.to_charlist(url), []}, [timeout: 10_000], [])
    |> case do
      {:ok, {{_, status, _}, _headers, body}} ->
        {:ok, %{status: status, body: List.to_string(body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp to_integer(nil), do: 0
  defp to_integer(%Decimal{} = d), do: Decimal.to_integer(d)
  defp to_integer(n) when is_integer(n), do: n
end
