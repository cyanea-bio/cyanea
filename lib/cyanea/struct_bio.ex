defmodule Cyanea.StructBio do
  @moduledoc "Protein/nucleic acid 3D structure analysis."

  import Cyanea.NifHelper
  alias Cyanea.Native

  @doc """
  Parse PDB data and return structure info.

  Accepts either PDB text content or a file path (detected by checking
  if the input ends with `.pdb`).
  """
  @spec parse_pdb(binary()) :: {:ok, struct()} | {:error, term()}
  def parse_pdb(text_or_path) when is_binary(text_or_path) do
    if String.ends_with?(text_or_path, ".pdb") do
      nif_call(fn -> Native.pdb_file_info(text_or_path) end)
    else
      nif_call(fn -> Native.pdb_info(text_or_path) end)
    end
  end

  @doc """
  Parse mmCIF data and return structure info.

  Accepts either mmCIF text content or a file path (detected by checking
  if the input ends with `.cif` or `.mmcif`).
  """
  @spec parse_mmcif(binary()) :: {:ok, struct()} | {:error, term()}
  def parse_mmcif(text_or_path) when is_binary(text_or_path) do
    if String.ends_with?(text_or_path, ".cif") or String.ends_with?(text_or_path, ".mmcif") do
      nif_call(fn -> Native.mmcif_file_info(text_or_path) end)
    else
      nif_call(fn -> Native.mmcif_info(text_or_path) end)
    end
  end

  @doc "Assign secondary structure (simplified DSSP) for a chain."
  @spec secondary_structure(binary(), binary()) :: {:ok, struct()} | {:error, term()}
  def secondary_structure(pdb_text, chain_id)
      when is_binary(pdb_text) and is_binary(chain_id),
      do: nif_call(fn -> Native.pdb_secondary_structure(pdb_text, chain_id) end)

  @doc "Compute RMSD between CA atoms of two chains."
  @spec rmsd(binary(), binary(), binary(), binary()) :: {:ok, float()} | {:error, term()}
  def rmsd(pdb_a, pdb_b, chain_a, chain_b)
      when is_binary(pdb_a) and is_binary(pdb_b)
      and is_binary(chain_a) and is_binary(chain_b),
      do: nif_call(fn -> Native.pdb_rmsd(pdb_a, pdb_b, chain_a, chain_b) end)

  @doc "Kabsch superposition of CA atoms. Returns RMSD, rotation, and translation."
  @spec kabsch(binary(), binary(), binary(), binary()) :: {:ok, struct()} | {:error, term()}
  def kabsch(pdb_a, pdb_b, chain_a, chain_b)
      when is_binary(pdb_a) and is_binary(pdb_b)
      and is_binary(chain_a) and is_binary(chain_b),
      do: nif_call(fn -> Native.pdb_kabsch(pdb_a, pdb_b, chain_a, chain_b) end)

  @doc """
  Compute contact map for a chain within cutoff distance.

  ## Options

    * `:cutoff` - distance cutoff in Angstroms (default: 8.0)

  """
  @spec contact_map(binary(), binary(), keyword()) :: {:ok, struct()} | {:error, term()}
  def contact_map(pdb_text, chain_id, opts \\ [])
      when is_binary(pdb_text) and is_binary(chain_id) do
    cutoff = Keyword.get(opts, :cutoff, 8.0)
    nif_call(fn -> Native.pdb_contact_map(pdb_text, chain_id, cutoff) end)
  end

  @doc "Compute Ramachandran phi/psi angles for all residues."
  @spec ramachandran(binary()) :: {:ok, list()} | {:error, term()}
  def ramachandran(pdb_text) when is_binary(pdb_text),
    do: nif_call(fn -> Native.pdb_ramachandran(pdb_text) end)

  @doc "Analyze B-factor distribution across the structure."
  @spec bfactors(binary()) :: {:ok, struct()} | {:error, term()}
  def bfactors(pdb_text) when is_binary(pdb_text),
    do: nif_call(fn -> Native.pdb_bfactor_analysis(pdb_text) end)
end
