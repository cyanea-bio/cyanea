defmodule Cyanea.Search do
  @moduledoc """
  Meilisearch integration for full-text search across repositories and users.
  All operations are gated by `:search_enabled` config.
  """

  @repo_index "repositories"
  @user_index "users"

  ## Index Setup

  @doc """
  Sets up Meilisearch indexes with proper settings. Idempotent.
  """
  def setup_indexes do
    unless search_enabled?(), do: throw(:search_disabled)

    # Create indexes (idempotent — will return error if exists, which is fine)
    Meilisearch.Indexes.create(@repo_index, primary_key: "id")
    Meilisearch.Indexes.create(@user_index, primary_key: "id")

    # Configure repositories index
    Meilisearch.Settings.update(@repo_index, %{
      searchableAttributes: ["name", "slug", "description", "tags", "owner_username", "org_name"],
      attributesForFaceting: ["visibility", "license", "tags"]
    })

    # Configure users index
    Meilisearch.Settings.update(@user_index, %{
      searchableAttributes: ["username", "name", "bio", "affiliation"]
    })

    :ok
  catch
    :search_disabled -> :ok
  end

  ## Indexing

  @doc """
  Indexes a repository in Meilisearch.
  """
  def index_repository(repo) do
    unless search_enabled?(), do: throw(:search_disabled)

    doc = %{
      id: repo.id,
      name: repo.name,
      slug: repo.slug,
      description: repo.description || "",
      visibility: repo.visibility,
      license: repo.license,
      tags: repo.tags || [],
      stars_count: repo.stars_count || 0,
      updated_at: repo.updated_at && DateTime.to_unix(repo.updated_at),
      owner_username: if(repo.owner, do: repo.owner.username, else: nil),
      org_name: if(repo.organization, do: repo.organization.name, else: nil)
    }

    Meilisearch.Documents.add_or_replace(@repo_index, [doc])
  catch
    :search_disabled -> :ok
  end

  @doc """
  Removes a repository from the search index.
  """
  def delete_repository(id) do
    unless search_enabled?(), do: throw(:search_disabled)
    Meilisearch.Documents.delete(@repo_index, id)
  catch
    :search_disabled -> :ok
  end

  @doc """
  Indexes a user in Meilisearch.
  """
  def index_user(user) do
    unless search_enabled?(), do: throw(:search_disabled)

    doc = %{
      id: user.id,
      username: user.username,
      name: user.name || "",
      bio: user.bio || "",
      affiliation: user.affiliation || ""
    }

    Meilisearch.Documents.add_or_replace(@user_index, [doc])
  catch
    :search_disabled -> :ok
  end

  @doc """
  Removes a user from the search index.
  """
  def delete_user(id) do
    unless search_enabled?(), do: throw(:search_disabled)
    Meilisearch.Documents.delete(@user_index, id)
  catch
    :search_disabled -> :ok
  end

  ## Searching

  @doc """
  Searches repositories. Returns `{:ok, results}` or `{:error, reason}`.

  Options:
    - `:limit` - Max results (default 20)
  """
  def search_repositories(query, opts \\ []) do
    unless search_enabled?(), do: throw(:search_disabled)

    search_opts = [limit: Keyword.get(opts, :limit, 20)]

    # Add filter if provided
    search_opts =
      case Keyword.get(opts, :filter) do
        nil -> search_opts
        filter -> [{:filters, filter} | search_opts]
      end

    Meilisearch.Search.search(@repo_index, query, search_opts)
  catch
    :search_disabled -> {:ok, %{"hits" => []}}
  end

  @doc """
  Searches users. Returns `{:ok, results}` or `{:error, reason}`.
  """
  def search_users(query, opts \\ []) do
    unless search_enabled?(), do: throw(:search_disabled)

    search_opts = [limit: Keyword.get(opts, :limit, 20)]
    Meilisearch.Search.search(@user_index, query, search_opts)
  catch
    :search_disabled -> {:ok, %{"hits" => []}}
  end

  ## Bulk Reindex

  @doc """
  Reindexes all public repositories.
  """
  def reindex_all_repositories do
    import Ecto.Query

    Cyanea.Repo.all(
      from(r in Cyanea.Repositories.Repository,
        where: r.visibility == "public",
        preload: [:owner, :organization]
      )
    )
    |> Enum.each(&index_repository/1)
  end

  @doc """
  Reindexes all users.
  """
  def reindex_all_users do
    Cyanea.Repo.all(Cyanea.Accounts.User)
    |> Enum.each(&index_user/1)
  end

  ## Helpers

  defp search_enabled? do
    Application.get_env(:cyanea, :search_enabled, false)
  end
end
