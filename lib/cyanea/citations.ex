defmodule Cyanea.Citations do
  @moduledoc """
  Context for generating citations, computing FAIR scores,
  listing contributors, and managing DOIs.
  """
  import Ecto.Query

  alias Cyanea.Repo
  alias Cyanea.Spaces
  alias Cyanea.Spaces.Space

  # -- Citation Generation --

  @doc """
  Generates a citation for a space in the given format.

  Supported formats: `:bibtex`, `:ris`, `:apa`
  """
  def cite(%Space{} = space, format) do
    owner_name = Spaces.owner_display(space)
    year = if space.inserted_at, do: space.inserted_at.year, else: Date.utc_today().year
    url = space_url(owner_name, space.slug)

    case format do
      :bibtex -> format_bibtex(space, owner_name, year, url)
      :ris -> format_ris(space, owner_name, year, url)
      :apa -> format_apa(space, owner_name, year, url)
    end
  end

  defp format_bibtex(space, owner_name, year, url) do
    doi_line = if space.doi, do: ",\n  doi = {#{space.doi}}", else: ""

    """
    @misc{cyanea:#{space.slug},
      title = {#{escape_bibtex(space.name)}},
      author = {#{escape_bibtex(owner_name)}},
      year = {#{year}},
      url = {#{url}},
      publisher = {Cyanea}#{doi_line}
    }
    """
    |> String.trim()
  end

  defp format_ris(space, owner_name, year, url) do
    doi_line = if space.doi, do: "DO  - #{space.doi}\n", else: ""

    """
    TY  - DATA
    TI  - #{space.name}
    AU  - #{owner_name}
    PY  - #{year}
    UR  - #{url}
    PB  - Cyanea
    #{doi_line}ER  -
    """
    |> String.trim()
  end

  defp format_apa(space, owner_name, year, url) do
    doi_part = if space.doi, do: " https://doi.org/#{space.doi}", else: ""
    "#{owner_name} (#{year}). #{space.name}. Cyanea. #{url}#{doi_part}"
  end

  # -- Contributors --

  @doc """
  Returns unique contributors to a space based on activity events.
  """
  def contributors(space_id) do
    # Query activity events for this space
    query =
      from(e in Cyanea.Activity.Event,
        where: e.space_id == ^space_id,
        distinct: e.actor_id,
        join: u in Cyanea.Accounts.User,
        on: u.id == e.actor_id,
        select: %{
          id: u.id,
          username: u.username,
          name: u.name,
          orcid_id: u.orcid_id
        }
      )

    Repo.all(query)
  rescue
    _ -> []
  end

  # -- FAIR Score --

  @doc """
  Computes a FAIR (Findable, Accessible, Interoperable, Reusable) score
  for a space on a 0-100 scale.
  """
  def fair_score(%Space{} = space) do
    findable = fair_findable(space)
    accessible = fair_accessible(space)
    interoperable = fair_interoperable(space)
    reusable = fair_reusable(space)

    total = findable + accessible + interoperable + reusable

    %{
      total: total,
      findable: findable,
      accessible: accessible,
      interoperable: interoperable,
      reusable: reusable
    }
  end

  defp fair_findable(space) do
    score = 0
    score = if space.description && space.description != "", do: score + 10, else: score
    score = if (space.tags || []) != [], do: score + 10, else: score
    # Indexed in search (public spaces are auto-indexed)
    score = if space.visibility == "public", do: score + 5, else: score
    score
  end

  defp fair_accessible(space) do
    score = 0
    score = if space.license, do: score + 10, else: score
    score = if space.visibility == "public", do: score + 10, else: score
    score = if space.global_id, do: score + 5, else: score
    score
  end

  defp fair_interoperable(space) do
    score = 0
    score = if (space.ontology_terms || []) != [], do: score + 10, else: score
    # Has structured metadata (tags count as structured)
    score = if (space.tags || []) != [] && (space.ontology_terms || []) != [], do: score + 10, else: score
    score
  end

  defp fair_reusable(space) do
    score = 0
    # Has revision history (current_revision_id set)
    score = if space.current_revision_id, do: score + 10, else: score
    # Has content hash via global_id
    score = if space.global_id, do: score + 10, else: score
    # Has DOI
    score = if space.doi, do: score + 10, else: score
    score
  end

  # -- DOI --

  @doc """
  Mints a DOI for a space via DataCite REST API.

  Returns `{:ok, doi}` or `{:error, reason}`.
  Requires DataCite configuration in application env.
  """
  def mint_doi(%Space{} = space) do
    if space.doi do
      {:ok, space.doi}
    else
      do_mint_doi(space)
    end
  end

  defp do_mint_doi(space) do
    config = Application.get_env(:cyanea, :datacite, [])

    prefix = Keyword.get(config, :prefix)
    api_url = Keyword.get(config, :api_url)
    username = Keyword.get(config, :username)
    password = Keyword.get(config, :password)

    if is_nil(prefix) or is_nil(api_url) do
      {:error, :datacite_not_configured}
    else
        doi = "#{prefix}/cyanea.#{space.id}"
        metadata = doi_metadata(space, doi)

        case Req.post("#{api_url}/dois",
               json: %{data: %{type: "dois", attributes: metadata}},
               auth: {:basic, "#{username}:#{password}"},
               headers: [{"content-type", "application/vnd.api+json"}]
             ) do
          {:ok, %{status: status}} when status in [200, 201] ->
            Spaces.update_space(space, %{doi: doi})
            {:ok, doi}

          {:ok, %{status: status, body: body}} ->
            {:error, "DataCite returned #{status}: #{inspect(body)}"}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Builds DataCite-compatible metadata for a space.
  """
  def doi_metadata(%Space{} = space, doi \\ nil) do
    owner_name = Spaces.owner_display(space)
    year = if space.inserted_at, do: space.inserted_at.year, else: Date.utc_today().year

    %{
      doi: doi || space.doi,
      titles: [%{title: space.name}],
      creators: [%{name: owner_name}],
      publisher: "Cyanea",
      publicationYear: year,
      types: %{resourceTypeGeneral: "Dataset"},
      descriptions:
        if(space.description,
          do: [%{description: space.description, descriptionType: "Abstract"}],
          else: []
        ),
      url: space_url(owner_name, space.slug)
    }
  end

  # -- Helpers --

  defp space_url(owner_name, slug) do
    host = Application.get_env(:cyanea, CyaneaWeb.Endpoint)[:url][:host] || "cyanea.dev"
    "https://#{host}/#{owner_name}/#{slug}"
  end

  defp escape_bibtex(str) do
    str
    |> String.replace("&", "\\&")
    |> String.replace("%", "\\%")
    |> String.replace("{", "\\{")
    |> String.replace("}", "\\}")
  end
end
