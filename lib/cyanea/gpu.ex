defmodule Cyanea.GPU do
  @moduledoc "GPU-accelerated compute operations."

  import Cyanea.NifHelper
  alias Cyanea.Native

  @doc "Get GPU backend info (available backends, current selection)."
  @spec info() :: {:ok, struct()} | {:error, term()}
  def info, do: nif_call(fn -> Native.gpu_info() end)

  @doc """
  Compute pairwise distance matrix on GPU.

  ## Options

    * `:metric` - `:euclidean` (default), `:manhattan`, or `:cosine`

  """
  @spec distances(list(), integer(), integer(), keyword()) :: {:ok, list()} | {:error, term()}
  def distances(data, n, dim, opts \\ [])
      when is_list(data) and is_integer(n) and is_integer(dim) do
    metric = metric_string(Keyword.get(opts, :metric, :euclidean))
    nif_call(fn -> Native.gpu_pairwise_distances(data, n, dim, metric) end)
  end

  @doc "Matrix multiplication on GPU (a: m*k, b: k*n -> result: m*n)."
  @spec matrix_multiply(list(), list(), integer(), integer(), integer()) :: {:ok, list()} | {:error, term()}
  def matrix_multiply(a, b, m, k, n)
      when is_list(a) and is_list(b) and is_integer(m) and is_integer(k) and is_integer(n),
      do: nif_call(fn -> Native.gpu_matrix_multiply(a, b, m, k, n) end)

  @doc "Sum reduction on GPU."
  @spec reduce_sum(list()) :: {:ok, float()} | {:error, term()}
  def reduce_sum(data) when is_list(data),
    do: nif_call(fn -> Native.gpu_reduce_sum(data) end)

  @doc "Batch z-score normalization on GPU (per-row)."
  @spec batch_z_score(list(), integer(), integer()) :: {:ok, list()} | {:error, term()}
  def batch_z_score(data, n_rows, n_cols)
      when is_list(data) and is_integer(n_rows) and is_integer(n_cols),
      do: nif_call(fn -> Native.gpu_batch_z_score(data, n_rows, n_cols) end)
end
