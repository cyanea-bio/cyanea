defmodule Cyanea.Ontologies do
  @moduledoc """
  Context for ontology term search and integration.

  Provides search against OLS4 (EMBL-EBI Ontology Lookup Service)
  and NCBI Taxonomy via Entrez eutils.
  """

  @ols4_base "https://www.ebi.ac.uk/ols4/api"
  @ncbi_base "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"

  @doc """
  Returns the list of available ontology sources.
  """
  def ontology_sources do
    [
      %{id: "go", name: "Gene Ontology"},
      %{id: "efo", name: "Experimental Factor Ontology"},
      %{id: "ncbitaxon", name: "NCBI Taxonomy"},
      %{id: "chebi", name: "Chemical Entities of Biological Interest"},
      %{id: "uberon", name: "Uberon Anatomy Ontology"},
      %{id: "cl", name: "Cell Ontology"},
      %{id: "doid", name: "Disease Ontology"}
    ]
  end

  @doc """
  Searches for ontology terms via the OLS4 API.

  Options:
    - `:ontology` — filter by specific ontology (e.g., "go", "efo")
    - `:limit` — max results (default 10)
  """
  def search_terms(query, opts \\ []) when is_binary(query) do
    if String.trim(query) == "" do
      {:ok, []}
    else
      ontology = Keyword.get(opts, :ontology)
      limit = Keyword.get(opts, :limit, 10)

      params = %{q: query, rows: limit}
      params = if ontology, do: Map.put(params, :ontology, ontology), else: params

      case Req.get("#{@ols4_base}/search", params: params) do
        {:ok, %{status: 200, body: body}} ->
          terms =
            body
            |> get_in(["response", "docs"])
            |> List.wrap()
            |> Enum.map(&format_ols_term/1)

          {:ok, terms}

        {:ok, %{status: status}} ->
          {:error, "OLS4 returned status #{status}"}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Searches for organisms in NCBI Taxonomy via Entrez eutils.
  """
  def search_organisms(query) when is_binary(query) do
    if String.trim(query) == "" do
      {:ok, []}
    else
      # Step 1: esearch to get IDs
      search_params = %{db: "taxonomy", term: query, retmode: "json", retmax: 10}

      with {:ok, %{status: 200, body: search_body}} <-
             Req.get("#{@ncbi_base}/esearch.fcgi", params: search_params),
           ids when ids != [] <- get_in(search_body, ["esearchresult", "idlist"]) |> List.wrap(),
           # Step 2: esummary to get details
           summary_params <- %{db: "taxonomy", id: Enum.join(ids, ","), retmode: "json"},
           {:ok, %{status: 200, body: summary_body}} <-
             Req.get("#{@ncbi_base}/esummary.fcgi", params: summary_params) do
        organisms =
          summary_body
          |> get_in(["result"])
          |> Map.drop(["uids"])
          |> Enum.map(fn {_id, data} ->
            %{
              taxon_id: data["taxid"] || data["uid"],
              scientific_name: data["scientificname"],
              common_name: data["commonname"],
              rank: data["rank"]
            }
          end)

        {:ok, organisms}
      else
        [] -> {:ok, []}
        {:ok, %{status: status}} -> {:error, "NCBI returned status #{status}"}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Normalizes an ontology term to a standard map format.
  """
  def format_ontology_term(%{id: id, label: label, source: source} = term) do
    %{
      id: id,
      label: label,
      source: source,
      uri: Map.get(term, :uri, "")
    }
  end

  def format_ontology_term(%{"id" => id, "label" => label} = term) do
    %{
      id: id,
      label: label,
      source: Map.get(term, "source", ""),
      uri: Map.get(term, "uri", "")
    }
  end

  def format_ontology_term(term) when is_map(term) do
    %{
      id: Map.get(term, :id) || Map.get(term, "id", ""),
      label: Map.get(term, :label) || Map.get(term, "label", ""),
      source: Map.get(term, :source) || Map.get(term, "source", ""),
      uri: Map.get(term, :uri) || Map.get(term, "uri", "")
    }
  end

  # -- Private --

  defp format_ols_term(doc) do
    %{
      id: doc["obo_id"] || doc["short_form"] || "",
      label: doc["label"] || "",
      source: doc["ontology_name"] || "",
      uri: doc["iri"] || ""
    }
  end
end
