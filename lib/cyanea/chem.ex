defmodule Cyanea.Chem do
  @moduledoc "Chemical informatics: SMILES parsing, fingerprints, similarity."

  import Cyanea.NifHelper
  alias Cyanea.Native

  @doc "Parse a SMILES string and compute molecular properties."
  @spec properties(binary()) :: {:ok, struct()} | {:error, term()}
  def properties(smiles) when is_binary(smiles),
    do: nif_call(fn -> Native.smiles_properties(smiles) end)

  @doc "Generate canonical SMILES from input SMILES."
  @spec canonical(binary()) :: {:ok, binary()} | {:error, term()}
  def canonical(smiles) when is_binary(smiles),
    do: nif_call(fn -> Native.canonical_smiles(smiles) end)

  @doc """
  Compute Morgan fingerprint as a byte vector.

  ## Options

    * `:radius` - Morgan radius (default: 2)
    * `:bits` - fingerprint length (default: 2048)

  """
  @spec fingerprint(binary(), keyword()) :: {:ok, binary()} | {:error, term()}
  def fingerprint(smiles, opts \\ []) when is_binary(smiles) do
    radius = Keyword.get(opts, :radius, 2)
    bits = Keyword.get(opts, :bits, 2048)
    nif_call(fn -> Native.smiles_fingerprint(smiles, radius, bits) end)
  end

  @doc "Compute MACCS fingerprint as byte vector."
  @spec maccs(binary()) :: {:ok, binary()} | {:error, term()}
  def maccs(smiles) when is_binary(smiles),
    do: nif_call(fn -> Native.maccs_fingerprint(smiles) end)

  @doc """
  Compute Tanimoto similarity between two SMILES via Morgan fingerprints.

  ## Options

    * `:radius` - Morgan radius (default: 2)
    * `:bits` - fingerprint length (default: 2048)

  """
  @spec tanimoto(binary(), binary(), keyword()) :: {:ok, float()} | {:error, term()}
  def tanimoto(smiles_a, smiles_b, opts \\ [])
      when is_binary(smiles_a) and is_binary(smiles_b) do
    radius = Keyword.get(opts, :radius, 2)
    bits = Keyword.get(opts, :bits, 2048)
    nif_call(fn -> Native.tanimoto(smiles_a, smiles_b, radius, bits) end)
  end

  @doc "Check if target SMILES contains the pattern as a substructure. Returns boolean."
  @spec substructure?(binary(), binary()) :: boolean()
  def substructure?(target, pattern) when is_binary(target) and is_binary(pattern) do
    case nif_call(fn -> Native.smiles_substructure(target, pattern) end) do
      {:ok, result} -> result
      {:error, _} -> false
    end
  end

  @doc "Parse an SDF file and return molecule summaries."
  @spec parse_sdf(binary()) :: {:ok, list()} | {:error, term()}
  def parse_sdf(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_sdf_file(path) end)
end
