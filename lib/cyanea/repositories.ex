defmodule Cyanea.Repositories do
  @moduledoc """
  The Repositories context - managing research data repositories.
  """
  import Ecto.Query

  alias Cyanea.Repo
  alias Cyanea.Repositories.Repository
  alias Cyanea.Organizations.Membership

  ## Listing

  @doc """
  Lists public repositories, ordered by most recently updated.
  """
  def list_public_repositories(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(r in Repository,
      where: r.visibility == "public",
      order_by: [desc: r.updated_at],
      limit: ^limit,
      preload: [:owner, :organization]
    )
    |> Repo.all()
  end

  @doc """
  Lists repositories owned by a user.
  """
  def list_user_repositories(user_id, opts \\ []) do
    visibility_filter = Keyword.get(opts, :visibility, nil)

    query =
      from(r in Repository,
        where: r.owner_id == ^user_id,
        order_by: [desc: r.updated_at],
        preload: [:owner, :organization]
      )

    query =
      if visibility_filter do
        from(r in query, where: r.visibility == ^visibility_filter)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Lists repositories belonging to an organization.
  """
  def list_org_repositories(organization_id, opts \\ []) do
    visibility_filter = Keyword.get(opts, :visibility, nil)

    query =
      from(r in Repository,
        where: r.organization_id == ^organization_id,
        order_by: [desc: r.updated_at],
        preload: [:owner, :organization]
      )

    query =
      if visibility_filter do
        from(r in query, where: r.visibility == ^visibility_filter)
      else
        query
      end

    Repo.all(query)
  end

  ## Fetching

  @doc """
  Gets a single repository by ID.

  Raises `Ecto.NoResultsError` if the Repository does not exist.
  """
  def get_repository!(id) do
    Repository
    |> Repo.get!(id)
    |> Repo.preload([:owner, :organization])
  end

  @doc """
  Gets a repository by owner username and slug.
  """
  def get_repository_by_owner_and_slug(username, slug) do
    from(r in Repository,
      join: u in assoc(r, :owner),
      where: u.username == ^String.downcase(username) and r.slug == ^String.downcase(slug),
      preload: [:owner, :organization]
    )
    |> Repo.one()
  end

  @doc """
  Gets a repository by organization slug and repo slug.
  """
  def get_repository_by_org_and_slug(org_slug, slug) do
    from(r in Repository,
      join: o in assoc(r, :organization),
      where: o.slug == ^String.downcase(org_slug) and r.slug == ^String.downcase(slug),
      preload: [:owner, :organization]
    )
    |> Repo.one()
  end

  ## Create / Update / Delete

  @doc """
  Creates a repository.
  """
  def create_repository(attrs) do
    %Repository{}
    |> Repository.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, repo} ->
        repo = Repo.preload(repo, [:owner, :organization])
        if repo.visibility == "public", do: Cyanea.Search.index_repository(repo)
        {:ok, repo}

      error ->
        error
    end
  end

  @doc """
  Updates a repository.
  """
  def update_repository(%Repository{} = repository, attrs) do
    repository
    |> Repository.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, repo} ->
        repo = Repo.preload(repo, [:owner, :organization])

        if repo.visibility == "public" do
          Cyanea.Search.index_repository(repo)
        else
          Cyanea.Search.delete_repository(repo.id)
        end

        {:ok, repo}

      error ->
        error
    end
  end

  @doc """
  Deletes a repository.
  """
  def delete_repository(%Repository{} = repository) do
    Cyanea.Search.delete_repository(repository.id)
    Repo.delete(repository)
  end

  ## Access Control

  @doc """
  Checks if a user can access a repository.

  Public repos are accessible to everyone. Private repos require
  the user to be the owner or a member of the owning organization.
  """
  def can_access?(repository, nil) do
    repository.visibility == "public"
  end

  def can_access?(repository, user) do
    cond do
      repository.visibility == "public" ->
        true

      repository.owner_id == user.id ->
        true

      repository.organization_id != nil ->
        membership =
          Repo.get_by(Membership,
            user_id: user.id,
            organization_id: repository.organization_id
          )

        membership != nil

      true ->
        false
    end
  end
end
