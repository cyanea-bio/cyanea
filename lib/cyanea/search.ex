defmodule Cyanea.Search do
  @moduledoc """
  Meilisearch integration for full-text search across spaces and users.
  All operations are gated by `:search_enabled` config.
  """

  @space_index "spaces"
  @user_index "users"

  ## Index Setup

  @doc """
  Sets up Meilisearch indexes with proper settings. Idempotent.
  """
  def setup_indexes do
    unless search_enabled?(), do: throw(:search_disabled)

    # Create indexes (idempotent — will return error if exists, which is fine)
    Meilisearch.Indexes.create(@space_index, primary_key: "id")
    Meilisearch.Indexes.create(@user_index, primary_key: "id")

    # Configure spaces index
    Meilisearch.Settings.update(@space_index, %{
      searchableAttributes: ["name", "slug", "description", "tags", "owner_name", "ontology_term_labels", "ontology_term_ids"],
      attributesForFaceting: ["visibility", "license", "tags", "ontology_term_ids"]
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
  Indexes a space in Meilisearch.
  """
  def index_space(space) do
    unless search_enabled?(), do: throw(:search_disabled)

    owner_name = Cyanea.Spaces.owner_display(space)

    ontology_terms = space.ontology_terms || []
    ontology_term_labels = Enum.map(ontology_terms, &(&1["label"] || ""))
    ontology_term_ids = Enum.map(ontology_terms, &(&1["id"] || ""))

    doc = %{
      id: space.id,
      name: space.name,
      slug: space.slug,
      description: space.description || "",
      visibility: space.visibility,
      license: space.license,
      tags: space.tags || [],
      star_count: space.star_count || 0,
      updated_at: space.updated_at && DateTime.to_unix(space.updated_at),
      owner_name: owner_name,
      ontology_term_labels: ontology_term_labels,
      ontology_term_ids: ontology_term_ids
    }

    Meilisearch.Documents.add_or_replace(@space_index, [doc])
  catch
    :search_disabled -> :ok
  end

  @doc """
  Removes a space from the search index.
  """
  def delete_space(id) do
    unless search_enabled?(), do: throw(:search_disabled)
    Meilisearch.Documents.delete(@space_index, id)
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
  Searches spaces. Returns `{:ok, results}` or `{:error, reason}`.

  Options:
    - `:limit` - Max results (default 20)
  """
  def search_spaces(query, opts \\ []) do
    unless search_enabled?(), do: throw(:search_disabled)

    search_opts = [limit: Keyword.get(opts, :limit, 20)]

    # Add filter if provided
    search_opts =
      case Keyword.get(opts, :filter) do
        nil -> search_opts
        filter -> [{:filters, filter} | search_opts]
      end

    Meilisearch.Search.search(@space_index, query, search_opts)
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
  Reindexes all public spaces.
  """
  def reindex_all_spaces do
    import Ecto.Query

    Cyanea.Repo.all(
      from(s in Cyanea.Spaces.Space,
        where: s.visibility == "public"
      )
    )
    |> Enum.each(&index_space/1)
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
