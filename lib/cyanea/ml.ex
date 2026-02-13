defmodule Cyanea.ML do
  @moduledoc "Machine learning: clustering, dimensionality reduction, classification."

  import Cyanea.NifHelper
  alias Cyanea.Native

  # ===========================================================================
  # Clustering
  # ===========================================================================

  @doc """
  K-means clustering.

  `data` is a flat list of floats (row-major), `n_features` per row.

  ## Options

    * `:max_iter` - maximum iterations (default: 100)
    * `:seed` - random seed (default: 42)

  """
  @spec kmeans(list(), integer(), integer(), keyword()) :: {:ok, struct()} | {:error, term()}
  def kmeans(data, n_features, k, opts \\ [])
      when is_list(data) and is_integer(n_features) and is_integer(k) do
    max_iter = Keyword.get(opts, :max_iter, 100)
    seed = Keyword.get(opts, :seed, 42)
    nif_call(fn -> Native.kmeans(data, n_features, k, max_iter, seed) end)
  end

  @doc """
  DBSCAN density-based clustering.

  ## Options

    * `:metric` - `:euclidean` (default), `:manhattan`, or `:cosine`

  """
  @spec dbscan(list(), integer(), number(), integer(), keyword()) :: {:ok, struct()} | {:error, term()}
  def dbscan(data, n_features, eps, min_samples, opts \\ [])
      when is_list(data) and is_integer(n_features)
      and is_number(eps) and is_integer(min_samples) do
    metric = metric_string(Keyword.get(opts, :metric, :euclidean))
    nif_call(fn -> Native.dbscan(data, n_features, eps, min_samples, metric) end)
  end

  @doc """
  Hierarchical (agglomerative) clustering.

  ## Options

    * `:linkage` - `:average` (default), `:single`, `:complete`, or `:ward`
    * `:metric` - `:euclidean` (default), `:manhattan`, or `:cosine`

  """
  @spec hierarchical(list(), integer(), integer(), keyword()) :: {:ok, struct()} | {:error, term()}
  def hierarchical(data, n_features, k, opts \\ [])
      when is_list(data) and is_integer(n_features) and is_integer(k) do
    linkage = linkage_string(Keyword.get(opts, :linkage, :average))
    metric = metric_string(Keyword.get(opts, :metric, :euclidean))
    nif_call(fn -> Native.hierarchical_cluster(data, n_features, k, linkage, metric) end)
  end

  # ===========================================================================
  # Dimensionality reduction
  # ===========================================================================

  @doc "Principal component analysis."
  @spec pca(list(), integer(), integer()) :: {:ok, struct()} | {:error, term()}
  def pca(data, n_features, n_components)
      when is_list(data) and is_integer(n_features) and is_integer(n_components),
      do: nif_call(fn -> Native.pca(data, n_features, n_components) end)

  @doc """
  t-SNE dimensionality reduction.

  ## Options

    * `:n_components` - output dimensions (default: 2)
    * `:perplexity` - perplexity parameter (default: 30.0)
    * `:n_iter` - number of iterations (default: 1000)

  """
  @spec tsne(list(), integer(), keyword()) :: {:ok, struct()} | {:error, term()}
  def tsne(data, n_features, opts \\ [])
      when is_list(data) and is_integer(n_features) do
    n_components = Keyword.get(opts, :n_components, 2)
    perplexity = Keyword.get(opts, :perplexity, 30.0)
    n_iter = Keyword.get(opts, :n_iter, 1000)
    nif_call(fn -> Native.tsne(data, n_features, n_components, perplexity, n_iter) end)
  end

  @doc """
  UMAP dimensionality reduction.

  ## Options

    * `:n_components` - output dimensions (default: 2)
    * `:n_neighbors` - number of neighbors (default: 15)
    * `:min_dist` - minimum distance (default: 0.1)
    * `:n_epochs` - number of epochs (default: 200)
    * `:metric` - `:euclidean` (default), `:manhattan`, or `:cosine`
    * `:seed` - random seed (default: 42)

  """
  @spec umap(list(), integer(), keyword()) :: {:ok, struct()} | {:error, term()}
  def umap(data, n_features, opts \\ [])
      when is_list(data) and is_integer(n_features) do
    n_components = Keyword.get(opts, :n_components, 2)
    n_neighbors = Keyword.get(opts, :n_neighbors, 15)
    min_dist = Keyword.get(opts, :min_dist, 0.1)
    n_epochs = Keyword.get(opts, :n_epochs, 200)
    metric = metric_string(Keyword.get(opts, :metric, :euclidean))
    seed = Keyword.get(opts, :seed, 42)
    nif_call(fn -> Native.umap(data, n_features, n_components, n_neighbors, min_dist, n_epochs, metric, seed) end)
  end

  # ===========================================================================
  # Embeddings & distances
  # ===========================================================================

  @doc """
  Compute normalized k-mer frequency embedding for a sequence.

  ## Options

    * `:alphabet` - `:dna` (default), `:rna`, or `:protein`

  """
  @spec embed(binary(), integer(), keyword()) :: {:ok, list()} | {:error, term()}
  def embed(sequence, k, opts \\ [])
      when is_binary(sequence) and is_integer(k) do
    alphabet = alphabet_string(Keyword.get(opts, :alphabet, :dna))
    nif_call(fn -> Native.kmer_embedding(sequence, k, alphabet) end)
  end

  @doc """
  Batch k-mer frequency embeddings for multiple sequences.

  ## Options

    * `:alphabet` - `:dna` (default), `:rna`, or `:protein`

  """
  @spec batch_embed(list(), integer(), keyword()) :: {:ok, list()} | {:error, term()}
  def batch_embed(sequences, k, opts \\ [])
      when is_list(sequences) and is_integer(k) do
    alphabet = alphabet_string(Keyword.get(opts, :alphabet, :dna))
    nif_call(fn -> Native.batch_embed(sequences, k, alphabet) end)
  end

  @doc """
  Compute pairwise distance matrix (condensed upper-triangle).

  ## Options

    * `:metric` - `:euclidean` (default), `:manhattan`, or `:cosine`

  """
  @spec distances(list(), integer(), keyword()) :: {:ok, list()} | {:error, term()}
  def distances(data, n_features, opts \\ [])
      when is_list(data) and is_integer(n_features) do
    metric = metric_string(Keyword.get(opts, :metric, :euclidean))
    nif_call(fn -> Native.pairwise_distances(data, n_features, metric) end)
  end

  # ===========================================================================
  # Classification & Regression
  # ===========================================================================

  @doc """
  K-nearest neighbor classification.

  ## Options

    * `:metric` - `:euclidean` (default), `:manhattan`, or `:cosine`

  """
  @spec knn(list(), integer(), integer(), list(), list(), keyword()) :: {:ok, integer()} | {:error, term()}
  def knn(data, n_features, k, labels, query, opts \\ [])
      when is_list(data) and is_integer(n_features) and is_integer(k)
      and is_list(labels) and is_list(query) do
    metric = metric_string(Keyword.get(opts, :metric, :euclidean))
    nif_call(fn -> Native.knn_classify(data, n_features, k, metric, labels, query) end)
  end

  @doc "Fit a linear regression model. Returns `{:ok, %LinearRegressionResult{}}`."
  @spec fit_linear(list(), integer(), list()) :: {:ok, struct()} | {:error, term()}
  def fit_linear(data, n_features, targets)
      when is_list(data) and is_integer(n_features) and is_list(targets),
      do: nif_call(fn -> Native.linear_regression_fit(data, n_features, targets) end)

  @doc "Predict using linear regression weights and bias."
  @spec predict_linear(list(), number(), list(), integer()) :: {:ok, list()} | {:error, term()}
  def predict_linear(weights, bias, queries, n_features)
      when is_list(weights) and is_number(bias) and is_list(queries) and is_integer(n_features),
      do: nif_call(fn -> Native.linear_regression_predict(weights, bias, queries, n_features) end)

  @doc """
  Fit a random forest classifier.

  ## Options

    * `:n_trees` - number of trees (default: 10)
    * `:max_depth` - maximum tree depth (default: 5)
    * `:seed` - random seed (default: 42)

  """
  @spec fit_forest(list(), integer(), list(), keyword()) :: {:ok, binary()} | {:error, term()}
  def fit_forest(data, n_features, labels, opts \\ [])
      when is_list(data) and is_integer(n_features) and is_list(labels) do
    n_trees = Keyword.get(opts, :n_trees, 10)
    max_depth = Keyword.get(opts, :max_depth, 5)
    seed = Keyword.get(opts, :seed, 42)
    nif_call(fn -> Native.random_forest_fit(data, n_features, labels, n_trees, max_depth, seed) end)
  end

  @doc "Predict class label using a serialized random forest model."
  @spec predict_forest(binary(), list(), integer()) :: {:ok, integer()} | {:error, term()}
  def predict_forest(model, sample, n_features)
      when is_binary(model) and is_list(sample) and is_integer(n_features),
      do: nif_call(fn -> Native.random_forest_predict(model, sample, n_features) end)

  # ===========================================================================
  # HMM
  # ===========================================================================

  @doc "HMM Viterbi decoding. Returns `{:ok, {most_likely_path, log_probability}}`."
  @spec hmm_viterbi(integer(), integer(), list(), list(), list(), list()) :: {:ok, {list(), float()}} | {:error, term()}
  def hmm_viterbi(n_states, n_symbols, initial, transition, emission, observations)
      when is_integer(n_states) and is_integer(n_symbols)
      and is_list(initial) and is_list(transition) and is_list(emission) and is_list(observations),
      do: nif_call(fn -> Native.hmm_viterbi(n_states, n_symbols, initial, transition, emission, observations) end)

  @doc "HMM forward algorithm. Returns log-probability of observation sequence."
  @spec hmm_forward(integer(), integer(), list(), list(), list(), list()) :: {:ok, float()} | {:error, term()}
  def hmm_forward(n_states, n_symbols, initial, transition, emission, observations)
      when is_integer(n_states) and is_integer(n_symbols)
      and is_list(initial) and is_list(transition) and is_list(emission) and is_list(observations),
      do: nif_call(fn -> Native.hmm_forward(n_states, n_symbols, initial, transition, emission, observations) end)

  # ===========================================================================
  # Normalization & evaluation
  # ===========================================================================

  @doc "Normalize data. Accepts `:min_max` or `:z_score`."
  @spec normalize(list(), :min_max | :z_score) :: {:ok, list()} | {:error, term()}
  def normalize(data, :min_max) when is_list(data),
    do: nif_call(fn -> Native.normalize_min_max(data) end)

  def normalize(data, :z_score) when is_list(data),
    do: nif_call(fn -> Native.normalize_z_score(data) end)

  @doc """
  Compute silhouette score for clustering quality.

  ## Options

    * `:metric` - `:euclidean` (default), `:manhattan`, or `:cosine`

  """
  @spec silhouette(list(), integer(), list(), keyword()) :: {:ok, float()} | {:error, term()}
  def silhouette(data, n_features, labels, opts \\ [])
      when is_list(data) and is_integer(n_features) and is_list(labels) do
    metric = metric_string(Keyword.get(opts, :metric, :euclidean))
    nif_call(fn -> Native.silhouette_score(data, n_features, labels, metric) end)
  end
end
