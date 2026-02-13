defmodule Cyanea.Stats do
  @moduledoc "Descriptive statistics, hypothesis testing, and distributions."

  import Cyanea.NifHelper
  alias Cyanea.Native

  # ===========================================================================
  # Descriptive
  # ===========================================================================

  @doc "Compute descriptive statistics (15 fields) for a list of floats."
  @spec describe(list()) :: {:ok, struct()} | {:error, term()}
  def describe(data) when is_list(data),
    do: nif_call(fn -> Native.descriptive_stats(data) end)

  # ===========================================================================
  # Correlation
  # ===========================================================================

  @doc """
  Compute correlation between two vectors.

  ## Options

    * `:method` - `:pearson` (default) or `:spearman`

  """
  @spec correlate(list(), list(), keyword()) :: {:ok, float()} | {:error, term()}
  def correlate(x, y, opts \\ []) when is_list(x) and is_list(y) do
    method = Keyword.get(opts, :method, :pearson)

    case method do
      :pearson -> nif_call(fn -> Native.pearson_correlation(x, y) end)
      :spearman -> nif_call(fn -> Native.spearman_correlation(x, y) end)
    end
  end

  # ===========================================================================
  # Hypothesis testing
  # ===========================================================================

  @doc """
  One-sample t-test (test if population mean equals mu).

  ## Options

    * `:mu` - hypothesized mean (default: 0.0)

  """
  @spec t_test(list(), keyword()) :: {:ok, struct()} | {:error, term()}
  def t_test(data, opts \\ [])

  def t_test(data, opts) when is_list(data) and is_list(opts) do
    mu = Keyword.get(opts, :mu, 0.0)
    nif_call(fn -> Native.t_test_one_sample(data, mu) end)
  end

  @doc """
  Two-sample t-test.

  ## Options

    * `:equal_var` - `true` for Student's, `false` for Welch's (default: `false`)

  """
  @spec t_test_two(list(), list(), keyword()) :: {:ok, struct()} | {:error, term()}
  def t_test_two(x, y, opts \\ []) when is_list(x) and is_list(y) do
    equal_var = Keyword.get(opts, :equal_var, false)
    nif_call(fn -> Native.t_test_two_sample(x, y, equal_var) end)
  end

  @doc "Mann-Whitney U test (non-parametric, two independent samples)."
  @spec mann_whitney(list(), list()) :: {:ok, struct()} | {:error, term()}
  def mann_whitney(x, y) when is_list(x) and is_list(y),
    do: nif_call(fn -> Native.mann_whitney_u(x, y) end)

  # ===========================================================================
  # P-value adjustment
  # ===========================================================================

  @doc """
  Adjust p-values for multiple comparisons.

  ## Options

    * `:method` - `:bonferroni` (default) or `:bh` (Benjamini-Hochberg)

  """
  @spec adjust(list(), keyword()) :: {:ok, list()} | {:error, term()}
  def adjust(p_values, opts \\ []) when is_list(p_values) do
    method = Keyword.get(opts, :method, :bonferroni)

    case method do
      :bonferroni -> nif_call(fn -> Native.p_adjust_bonferroni(p_values) end)
      :bh -> nif_call(fn -> Native.p_adjust_bh(p_values) end)
    end
  end

  # ===========================================================================
  # Effect sizes
  # ===========================================================================

  @doc "Cohen's d effect size between two groups."
  @spec cohens_d(list(), list()) :: {:ok, float()} | {:error, term()}
  def cohens_d(group1, group2) when is_list(group1) and is_list(group2),
    do: nif_call(fn -> Native.cohens_d(group1, group2) end)

  @doc "Odds ratio from a 2x2 contingency table (a, b, c, d)."
  @spec odds_ratio(integer(), integer(), integer(), integer()) :: {:ok, float()} | {:error, term()}
  def odds_ratio(a, b, c, d)
      when is_integer(a) and is_integer(b) and is_integer(c) and is_integer(d),
      do: nif_call(fn -> Native.odds_ratio(a, b, c, d) end)

  # ===========================================================================
  # Distributions
  # ===========================================================================

  @doc """
  Normal distribution CDF at x.

  ## Options

    * `:mu` - mean (default: 0.0)
    * `:sigma` - standard deviation (default: 1.0)

  """
  @spec normal_cdf(number(), keyword()) :: {:ok, float()} | {:error, term()}
  def normal_cdf(x, opts \\ []) when is_number(x) do
    mu = Keyword.get(opts, :mu, 0.0)
    sigma = Keyword.get(opts, :sigma, 1.0)
    nif_call(fn -> Native.normal_cdf(x, mu, sigma) end)
  end

  @doc """
  Normal distribution PDF at x.

  ## Options

    * `:mu` - mean (default: 0.0)
    * `:sigma` - standard deviation (default: 1.0)

  """
  @spec normal_pdf(number(), keyword()) :: {:ok, float()} | {:error, term()}
  def normal_pdf(x, opts \\ []) when is_number(x) do
    mu = Keyword.get(opts, :mu, 0.0)
    sigma = Keyword.get(opts, :sigma, 1.0)
    nif_call(fn -> Native.normal_pdf(x, mu, sigma) end)
  end

  @doc "Chi-squared distribution CDF at x with df degrees of freedom."
  @spec chi_squared_cdf(number(), number()) :: {:ok, float()} | {:error, term()}
  def chi_squared_cdf(x, df) when is_number(x) and is_number(df),
    do: nif_call(fn -> Native.chi_squared_cdf(x, df) end)

  # ===========================================================================
  # Bayesian
  # ===========================================================================

  @doc """
  Bayesian beta-binomial conjugate update.

  ## Options

    * `:alpha` - prior alpha (required)
    * `:beta` - prior beta (required)
    * `:successes` - observed successes (required)
    * `:trials` - total trials (required)

  Returns `{:ok, {posterior_alpha, posterior_beta}}`.
  """
  @spec bayesian_update(:beta, keyword()) :: {:ok, {float(), float()}} | {:error, term()}
  def bayesian_update(:beta, opts) do
    alpha = Keyword.fetch!(opts, :alpha)
    beta = Keyword.fetch!(opts, :beta)
    successes = Keyword.fetch!(opts, :successes)
    trials = Keyword.fetch!(opts, :trials)
    nif_call(fn -> Native.bayesian_beta_update(alpha, beta, successes, trials) end)
  end
end
