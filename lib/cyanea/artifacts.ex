defmodule Cyanea.Artifacts do
  @moduledoc """
  The Artifacts context — typed, versioned scientific objects.

  Manages the lifecycle of artifacts (datasets, protocols, notebooks,
  pipelines, results, samples) within repositories. Supports versioning,
  lineage tracking via parent references, and an append-only event log.
  """
  import Ecto.Query

  alias Cyanea.Repo
  alias Cyanea.Artifacts.{Artifact, ArtifactEvent, ArtifactFile}

  # ===========================================================================
  # Listing
  # ===========================================================================

  @doc """
  Lists artifacts in a repository, ordered by most recently updated.
  """
  def list_repository_artifacts(repository_id, opts \\ []) do
    type_filter = Keyword.get(opts, :type, nil)
    limit = Keyword.get(opts, :limit, 50)

    query =
      from(a in Artifact,
        where: a.repository_id == ^repository_id,
        order_by: [desc: a.updated_at],
        limit: ^limit,
        preload: [:author]
      )

    query =
      if type_filter do
        from(a in query, where: a.type == ^type_filter)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Lists public artifacts across all repositories.
  """
  def list_public_artifacts(opts \\ []) do
    type_filter = Keyword.get(opts, :type, nil)
    limit = Keyword.get(opts, :limit, 50)

    query =
      from(a in Artifact,
        where: a.visibility == "public",
        order_by: [desc: a.updated_at],
        limit: ^limit,
        preload: [:author, :repository]
      )

    query =
      if type_filter do
        from(a in query, where: a.type == ^type_filter)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Lists artifacts authored by a user.
  """
  def list_user_artifacts(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(a in Artifact,
      where: a.author_id == ^user_id,
      order_by: [desc: a.updated_at],
      limit: ^limit,
      preload: [:repository]
    )
    |> Repo.all()
  end

  @doc """
  Lists artifacts derived from a given parent artifact.
  """
  def list_derived_artifacts(parent_artifact_id) do
    from(a in Artifact,
      where: a.parent_artifact_id == ^parent_artifact_id,
      order_by: [desc: a.inserted_at],
      preload: [:author]
    )
    |> Repo.all()
  end

  # ===========================================================================
  # Fetching
  # ===========================================================================

  @doc """
  Gets a single artifact by ID.

  Raises `Ecto.NoResultsError` if the Artifact does not exist.
  """
  def get_artifact!(id) do
    Artifact
    |> Repo.get!(id)
    |> Repo.preload([:author, :repository, :parent_artifact])
  end

  @doc """
  Gets an artifact by repository ID and slug.
  """
  def get_artifact_by_repo_and_slug(repository_id, slug) do
    from(a in Artifact,
      where: a.repository_id == ^repository_id and a.slug == ^String.downcase(slug),
      preload: [:author, :repository, :parent_artifact]
    )
    |> Repo.one()
  end

  @doc """
  Gets an artifact by its global federation ID.
  """
  def get_artifact_by_global_id(global_id) do
    Repo.get_by(Artifact, global_id: global_id)
    |> case do
      nil -> nil
      artifact -> Repo.preload(artifact, [:author, :repository])
    end
  end

  # ===========================================================================
  # Create / Update / Delete
  # ===========================================================================

  @doc """
  Creates an artifact and records a `created` event.
  """
  def create_artifact(attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:artifact, Artifact.changeset(%Artifact{}, attrs))
    |> Ecto.Multi.insert(:event, fn %{artifact: artifact} ->
      ArtifactEvent.changeset(%ArtifactEvent{}, %{
        event_type: "created",
        artifact_id: artifact.id,
        actor_id: artifact.author_id,
        payload: %{type: artifact.type, version: artifact.version}
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{artifact: artifact}} ->
        artifact = Repo.preload(artifact, [:author, :repository])
        {:ok, artifact}

      {:error, :artifact, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates an artifact and records an `updated` event.
  """
  def update_artifact(%Artifact{} = artifact, attrs, actor_id \\ nil) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:artifact, Artifact.changeset(artifact, attrs))
    |> Ecto.Multi.insert(:event, fn %{artifact: updated} ->
      ArtifactEvent.changeset(%ArtifactEvent{}, %{
        event_type: "updated",
        artifact_id: updated.id,
        actor_id: actor_id || updated.author_id,
        payload: %{changes: Map.keys(attrs)}
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{artifact: artifact}} ->
        artifact = Repo.preload(artifact, [:author, :repository])
        {:ok, artifact}

      {:error, :artifact, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Bumps the version of an artifact and records a `version_bumped` event.
  """
  def bump_version(%Artifact{} = artifact, new_version, actor_id) do
    old_version = artifact.version

    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :artifact,
      Artifact.changeset(artifact, %{version: new_version})
    )
    |> Ecto.Multi.insert(:event, fn %{artifact: updated} ->
      ArtifactEvent.changeset(%ArtifactEvent{}, %{
        event_type: "version_bumped",
        artifact_id: updated.id,
        actor_id: actor_id,
        payload: %{from: old_version, to: new_version}
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{artifact: artifact}} -> {:ok, Repo.preload(artifact, [:author, :repository])}
      {:error, :artifact, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Creates a derived artifact from a parent, recording lineage.
  """
  def derive_artifact(%Artifact{} = parent, attrs) do
    attrs =
      attrs
      |> Map.put(:parent_artifact_id, parent.id)
      |> Map.put(:repository_id, Map.get(attrs, :repository_id, parent.repository_id))

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:artifact, Artifact.changeset(%Artifact{}, attrs))
    |> Ecto.Multi.insert(:event, fn %{artifact: derived} ->
      ArtifactEvent.changeset(%ArtifactEvent{}, %{
        event_type: "derived",
        artifact_id: derived.id,
        actor_id: derived.author_id,
        payload: %{parent_id: parent.id, parent_type: parent.type}
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{artifact: artifact}} ->
        artifact = Repo.preload(artifact, [:author, :repository, :parent_artifact])
        {:ok, artifact}

      {:error, :artifact, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes an artifact and its events.
  """
  def delete_artifact(%Artifact{} = artifact) do
    Repo.delete(artifact)
  end

  # ===========================================================================
  # Files
  # ===========================================================================

  @doc """
  Lists files attached to an artifact.
  """
  def list_artifact_files(artifact_id) do
    from(af in ArtifactFile,
      where: af.artifact_id == ^artifact_id,
      order_by: [asc: af.path],
      preload: [:file]
    )
    |> Repo.all()
  end

  @doc """
  Attaches a file to an artifact at a given path.
  """
  def attach_file(%Artifact{} = artifact, file_id, path, actor_id \\ nil) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :artifact_file,
      ArtifactFile.changeset(%ArtifactFile{}, %{
        artifact_id: artifact.id,
        file_id: file_id,
        path: path
      })
    )
    |> Ecto.Multi.insert(:event, fn _changes ->
      ArtifactEvent.changeset(%ArtifactEvent{}, %{
        event_type: "files_changed",
        artifact_id: artifact.id,
        actor_id: actor_id || artifact.author_id,
        payload: %{action: "attached", path: path, file_id: file_id}
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{artifact_file: af}} -> {:ok, Repo.preload(af, [:file])}
      {:error, :artifact_file, changeset, _} -> {:error, changeset}
    end
  end

  # ===========================================================================
  # Events / Audit trail
  # ===========================================================================

  @doc """
  Lists events for an artifact, ordered chronologically.
  """
  def list_artifact_events(artifact_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(e in ArtifactEvent,
      where: e.artifact_id == ^artifact_id,
      order_by: [asc: e.inserted_at],
      limit: ^limit,
      preload: [:actor]
    )
    |> Repo.all()
  end

  # ===========================================================================
  # Lineage
  # ===========================================================================

  @doc """
  Returns the full lineage chain (list of ancestors) for an artifact.
  Walks up the parent chain until reaching a root artifact (no parent).
  """
  def lineage(%Artifact{parent_artifact_id: nil}), do: []

  def lineage(%Artifact{parent_artifact_id: parent_id}) do
    parent = get_artifact!(parent_id)
    [parent | lineage(parent)]
  end

  # ===========================================================================
  # Access Control
  # ===========================================================================

  @doc """
  Checks if a user can access an artifact.

  Public artifacts are accessible to everyone. Private and internal
  artifacts require the user to be the author or have access to the
  owning repository.
  """
  def can_access?(%Artifact{visibility: "public"}, _user), do: true
  def can_access?(_artifact, nil), do: false
  def can_access?(%Artifact{author_id: author_id}, %{id: user_id}) when author_id == user_id, do: true

  def can_access?(%Artifact{} = artifact, user) do
    artifact = Repo.preload(artifact, :repository)
    Cyanea.Repositories.can_access?(artifact.repository, user)
  end
end
