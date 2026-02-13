defmodule Cyanea.NifHelper do
  @moduledoc false

  @doc "Wrap a NIF call, normalizing bare returns to {:ok, result} tuples."
  def nif_call(fun) do
    case fun.() do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
      result -> {:ok, result}
    end
  rescue
    ErlangError -> {:error, :nif_not_loaded}
  end

  @doc "Convert atom/string alignment mode to string."
  def mode_string(:local), do: "local"
  def mode_string(:global), do: "global"
  def mode_string(:semiglobal), do: "semiglobal"
  def mode_string(s) when is_binary(s), do: s

  @doc "Convert atom/string distance metric to string."
  def metric_string(:euclidean), do: "euclidean"
  def metric_string(:manhattan), do: "manhattan"
  def metric_string(:cosine), do: "cosine"
  def metric_string(:hamming), do: "hamming"
  def metric_string(s) when is_binary(s), do: s

  @doc "Convert atom/string linkage method to string."
  def linkage_string(:single), do: "single"
  def linkage_string(:complete), do: "complete"
  def linkage_string(:average), do: "average"
  def linkage_string(:ward), do: "ward"
  def linkage_string(s) when is_binary(s), do: s

  @doc "Convert atom/string scoring matrix to string."
  def matrix_string(:blosum62), do: "blosum62"
  def matrix_string(:blosum45), do: "blosum45"
  def matrix_string(:blosum80), do: "blosum80"
  def matrix_string(:pam250), do: "pam250"
  def matrix_string(s) when is_binary(s), do: s

  @doc "Convert atom/string evolutionary model to string."
  def model_string(:p), do: "p"
  def model_string(:jc), do: "jc"
  def model_string(:k2p), do: "k2p"
  def model_string(s) when is_binary(s), do: s

  @doc "Convert atom/string alphabet to string."
  def alphabet_string(:dna), do: "dna"
  def alphabet_string(:rna), do: "rna"
  def alphabet_string(:protein), do: "protein"
  def alphabet_string(s) when is_binary(s), do: s

  @doc "Convert atom/string correlation method to string."
  def correlation_string(:pearson), do: "pearson"
  def correlation_string(:spearman), do: "spearman"
  def correlation_string(s) when is_binary(s), do: s

  @doc "Convert atom/string p-value adjustment method to string."
  def adjust_string(:bonferroni), do: "bonferroni"
  def adjust_string(:bh), do: "bh"
  def adjust_string(s) when is_binary(s), do: s

  @doc "Convert atom/string MSA mode to string."
  def msa_mode_string(:dna), do: "dna"
  def msa_mode_string(:protein), do: "protein"
  def msa_mode_string(s) when is_binary(s), do: s
end
