defmodule Cyanea.Spaces do
  @moduledoc """
  The Spaces context — managing research spaces.

  Spaces are the top-level container in Cyanea, replacing the old
  Repository/Artifact model. Ownership is polymorphic (user or organization).
  """
  import Ecto.Query

  alias Cyanea.Datasets
  alias Cyanea.Notebooks
  alias Cyanea.Organizations.Membership
  alias Cyanea.Protocols
  alias Cyanea.Repo
  alias Cyanea.Spaces.Space

  ## Listing

  @doc """
  Lists public spaces, ordered by most recently updated.
  """
  def list_public_spaces(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(s in Space,
      where: s.visibility == "public",
      order_by: [desc: s.updated_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Lists spaces owned by a user.
  """
  def list_user_spaces(user_id, opts \\ []) do
    visibility_filter = Keyword.get(opts, :visibility, nil)

    query =
      from(s in Space,
        where: s.owner_type == "user" and s.owner_id == ^user_id,
        order_by: [desc: s.updated_at]
      )

    query =
      if visibility_filter do
        from(s in query, where: s.visibility == ^visibility_filter)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Lists spaces owned by an organization.
  """
  def list_org_spaces(organization_id, opts \\ []) do
    visibility_filter = Keyword.get(opts, :visibility, nil)

    query =
      from(s in Space,
        where: s.owner_type == "organization" and s.owner_id == ^organization_id,
        order_by: [desc: s.updated_at]
      )

    query =
      if visibility_filter do
        from(s in query, where: s.visibility == ^visibility_filter)
      else
        query
      end

    Repo.all(query)
  end

  ## Fetching

  @doc """
  Gets a single space by ID.

  Raises `Ecto.NoResultsError` if the Space does not exist.
  """
  def get_space!(id) do
    Repo.get!(Space, id)
  end

  @doc """
  Gets a space by owner name and slug.

  Tries user-owned first (joins users table), then org-owned (joins organizations table).
  """
  def get_space_by_owner_and_slug(owner_name, slug) do
    owner_name = String.downcase(owner_name)
    slug = String.downcase(slug)

    # Try user-owned
    user_space =
      from(s in Space,
        join: u in Cyanea.Accounts.User,
        on: u.id == s.owner_id and s.owner_type == "user",
        where: u.username == ^owner_name and s.slug == ^slug
      )
      |> Repo.one()

    case user_space do
      nil ->
        # Try org-owned
        from(s in Space,
          join: o in Cyanea.Organizations.Organization,
          on: o.id == s.owner_id and s.owner_type == "organization",
          where: o.slug == ^owner_name and s.slug == ^slug
        )
        |> Repo.one()

      space ->
        space
    end
  end

  ## Create / Update / Delete

  @doc """
  Creates a space.
  """
  def create_space(attrs) do
    %Space{}
    |> Space.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, space} ->
        if space.visibility == "public", do: Cyanea.Search.index_space(space)
        {:ok, space}

      error ->
        error
    end
  end

  @doc """
  Updates a space.
  """
  def update_space(%Space{} = space, attrs) do
    space
    |> Space.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, space} ->
        if space.visibility == "public" do
          Cyanea.Search.index_space(space)
        else
          Cyanea.Search.delete_space(space.id)
        end

        {:ok, space}

      error ->
        error
    end
  end

  @doc """
  Deletes a space.
  """
  def delete_space(%Space{} = space) do
    Cyanea.Search.delete_space(space.id)
    Repo.delete(space)
  end

  ## Access Control

  @doc """
  Checks if a user can access a space.

  Public spaces are accessible to everyone. Private spaces require
  the user to be the owner or a member of the owning organization.
  """
  def can_access?(space, nil) do
    space.visibility == "public"
  end

  def can_access?(space, user) do
    cond do
      space.visibility == "public" ->
        true

      space.owner_type == "user" && space.owner_id == user.id ->
        true

      space.owner_type == "organization" ->
        membership =
          Repo.get_by(Membership,
            user_id: user.id,
            organization_id: space.owner_id
          )

        membership != nil

      true ->
        false
    end
  end

  @doc """
  Checks if a user is the owner of a space.
  """
  def owner?(%Space{owner_type: "user", owner_id: owner_id}, %{id: user_id}) do
    owner_id == user_id
  end

  def owner?(_space, _user), do: false

  @doc """
  Returns the display name for a space's owner.
  """
  def owner_display(%Space{owner_type: "user", owner_id: owner_id}) do
    case Repo.get(Cyanea.Accounts.User, owner_id) do
      nil -> "unknown"
      user -> user.username
    end
  end

  def owner_display(%Space{owner_type: "organization", owner_id: owner_id}) do
    case Repo.get(Cyanea.Organizations.Organization, owner_id) do
      nil -> "unknown"
      org -> org.slug
    end
  end

  ## Forking

  @doc """
  Deep-copies a space for a user: creates new space with forked_from_id,
  copies notebooks, protocols, datasets (referencing same blobs), and space_files.
  Atomically increments fork_count on the original space.
  """
  def fork_space(%Space{} = source, user, attrs \\ %{}) do
    fork_slug = Map.get(attrs, :slug, source.slug <> "-fork")
    fork_name = Map.get(attrs, :name, source.name <> " (fork)")

    space_attrs =
      valid_fork_attrs(source, user, fork_name, fork_slug)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:space, Space.changeset(%Space{}, space_attrs))
      |> Ecto.Multi.update_all(:increment_forks, fn _changes ->
        from(s in Space, where: s.id == ^source.id, update: [inc: [fork_count: 1]])
      end, [])
      |> Ecto.Multi.run(:copy_content, fn repo, %{space: forked_space} ->
        copy_notebooks(repo, source.id, forked_space.id)
        copy_protocols(repo, source.id, forked_space.id)
        copy_datasets(repo, source.id, forked_space.id)
        copy_space_files(repo, source.id, forked_space.id)
        {:ok, forked_space}
      end)

    case Repo.transaction(multi) do
      {:ok, %{space: forked_space}} ->
        if forked_space.visibility == "public", do: Cyanea.Search.index_space(forked_space)
        {:ok, forked_space}

      {:error, :space, changeset, _} ->
        {:error, changeset}

      {:error, _, reason, _} ->
        {:error, reason}
    end
  end

  @doc """
  Lists spaces forked from a given space.
  """
  def list_forks(space_id) do
    from(s in Space,
      where: s.forked_from_id == ^space_id,
      order_by: [desc: s.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Lists trending public spaces, sorted by star_count descending.
  """
  def list_trending_spaces(opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    from(s in Space,
      where: s.visibility == "public" and s.star_count > 0,
      order_by: [desc: s.star_count],
      limit: ^limit
    )
    |> Repo.all()
  end

  ## Fork helpers

  defp valid_fork_attrs(source, user, name, slug) do
    %{
      name: name,
      slug: slug,
      description: source.description,
      visibility: "public",
      license: source.license,
      owner_type: "user",
      owner_id: user.id,
      forked_from_id: source.id,
      tags: source.tags || [],
      ontology_terms: source.ontology_terms || []
    }
  end

  defp copy_notebooks(_repo, source_space_id, target_space_id) do
    Notebooks.list_space_notebooks(source_space_id)
    |> Enum.each(fn nb ->
      Notebooks.create_notebook(%{
        space_id: target_space_id,
        title: nb.title,
        slug: nb.slug,
        content: nb.content,
        position: nb.position
      })
    end)
  end

  defp copy_protocols(_repo, source_space_id, target_space_id) do
    Protocols.list_space_protocols(source_space_id)
    |> Enum.each(fn p ->
      Protocols.create_protocol(%{
        space_id: target_space_id,
        title: p.title,
        slug: p.slug,
        description: p.description,
        content: p.content,
        version: "1.0.0",
        position: p.position
      })
    end)
  end

  defp copy_datasets(_repo, source_space_id, target_space_id) do
    Datasets.list_space_datasets(source_space_id)
    |> Enum.each(fn ds ->
      case Datasets.create_dataset(%{
             space_id: target_space_id,
             name: ds.name,
             slug: ds.slug,
             description: ds.description,
             storage_type: ds.storage_type,
             external_url: ds.external_url,
             metadata: ds.metadata,
             tags: ds.tags,
             position: ds.position
           }) do
        {:ok, new_ds} ->
          # Copy dataset files (reference same blobs)
          Datasets.list_dataset_files(ds.id)
          |> Enum.each(fn df ->
            Datasets.attach_file(new_ds, df.blob_id, df.path, size: df.size)
          end)

        _ ->
          :ok
      end
    end)
  end

  defp copy_space_files(_repo, source_space_id, target_space_id) do
    Cyanea.Blobs.list_space_files(source_space_id)
    |> Enum.each(fn sf ->
      Cyanea.Blobs.attach_file_to_space(target_space_id, sf.blob_id, sf.path || sf.name, sf.name)
    end)
  end
end
