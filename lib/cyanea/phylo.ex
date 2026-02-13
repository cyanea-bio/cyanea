defmodule Cyanea.Phylo do
  @moduledoc "Phylogenetic tree construction, comparison, and analysis."

  import Cyanea.NifHelper
  alias Cyanea.Native

  # ===========================================================================
  # Parsing
  # ===========================================================================

  @doc "Parse a Newick string and return tree info."
  @spec parse_newick(binary()) :: {:ok, struct()} | {:error, term()}
  def parse_newick(newick) when is_binary(newick),
    do: nif_call(fn -> Native.newick_info(newick) end)

  @doc "Parse NEXUS format text and return taxa and tree data."
  @spec parse_nexus(binary()) :: {:ok, struct()} | {:error, term()}
  def parse_nexus(nexus_text) when is_binary(nexus_text),
    do: nif_call(fn -> Native.nexus_parse(nexus_text) end)

  @doc "Write taxa and trees to NEXUS format string."
  @spec write_nexus(list(), list()) :: {:ok, binary()} | {:error, term()}
  def write_nexus(taxa, trees) when is_list(taxa) and is_list(trees),
    do: nif_call(fn -> Native.nexus_write(taxa, trees) end)

  # ===========================================================================
  # Distances
  # ===========================================================================

  @doc """
  Compute evolutionary distance between two aligned sequences.

  ## Options

    * `:model` - `:p` (default), `:jc`, or `:k2p`

  """
  @spec distance(binary(), binary(), keyword()) :: {:ok, float()} | {:error, term()}
  def distance(seq_a, seq_b, opts \\ [])
      when is_binary(seq_a) and is_binary(seq_b) do
    model = model_string(Keyword.get(opts, :model, :p))
    nif_call(fn -> Native.evolutionary_distance(seq_a, seq_b, model) end)
  end

  @doc """
  Compute Robinson-Foulds distance between two Newick trees.

  ## Options

    * `:normalized` - if `true`, returns normalized distance 0.0-1.0 (default: `false`)

  """
  @spec robinson_foulds(binary(), binary(), keyword()) :: {:ok, number()} | {:error, term()}
  def robinson_foulds(newick_a, newick_b, opts \\ [])
      when is_binary(newick_a) and is_binary(newick_b) do
    if Keyword.get(opts, :normalized, false) do
      nif_call(fn -> Native.robinson_foulds_normalized(newick_a, newick_b) end)
    else
      nif_call(fn -> Native.newick_robinson_foulds(newick_a, newick_b) end)
    end
  end

  @doc "Branch score distance between two trees."
  @spec branch_score(binary(), binary()) :: {:ok, float()} | {:error, term()}
  def branch_score(newick_a, newick_b)
      when is_binary(newick_a) and is_binary(newick_b),
      do: nif_call(fn -> Native.branch_score_distance(newick_a, newick_b) end)

  # ===========================================================================
  # Tree building
  # ===========================================================================

  @doc """
  Build a UPGMA tree from aligned sequences. Returns Newick string.

  ## Options

    * `:model` - `:p` (default), `:jc`, or `:k2p`

  """
  @spec build_upgma(list(), list(), keyword()) :: {:ok, binary()} | {:error, term()}
  def build_upgma(sequences, names, opts \\ [])
      when is_list(sequences) and is_list(names) do
    model = model_string(Keyword.get(opts, :model, :p))
    nif_call(fn -> Native.build_upgma(sequences, names, model) end)
  end

  @doc """
  Build a Neighbor-Joining tree from aligned sequences. Returns Newick string.

  ## Options

    * `:model` - `:p` (default), `:jc`, or `:k2p`

  """
  @spec build_nj(list(), list(), keyword()) :: {:ok, binary()} | {:error, term()}
  def build_nj(sequences, names, opts \\ [])
      when is_list(sequences) and is_list(names) do
    model = model_string(Keyword.get(opts, :model, :p))
    nif_call(fn -> Native.build_nj(sequences, names, model) end)
  end

  # ===========================================================================
  # Bootstrap & ancestral
  # ===========================================================================

  @doc """
  Compute bootstrap support values for tree branches.

  ## Options

    * `:n_replicates` - number of bootstrap replicates (default: 100)
    * `:model` - `:p` (default), `:jc`, or `:k2p`

  """
  @spec bootstrap(list(), binary(), keyword()) :: {:ok, list()} | {:error, term()}
  def bootstrap(sequences, tree, opts \\ [])
      when is_list(sequences) and is_binary(tree) do
    n_replicates = Keyword.get(opts, :n_replicates, 100)
    model = model_string(Keyword.get(opts, :model, :p))
    nif_call(fn -> Native.bootstrap_support(sequences, tree, n_replicates, model) end)
  end

  @doc "Ancestral state reconstruction using Fitch parsimony."
  @spec ancestral_states(binary(), list()) :: {:ok, list()} | {:error, term()}
  def ancestral_states(tree, leaf_states)
      when is_binary(tree) and is_list(leaf_states),
      do: nif_call(fn -> Native.ancestral_reconstruction(tree, leaf_states) end)
end
