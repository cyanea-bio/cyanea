defmodule Cyanea.StatsTest do
  use ExUnit.Case, async: true

  alias Cyanea.Stats

  # ===========================================================================
  # Descriptive
  # ===========================================================================

  describe "describe/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Stats.describe([1.0, 2.0, 3.0])
    end

    test "rejects non-list" do
      assert_raise FunctionClauseError, fn -> Stats.describe("not a list") end
    end
  end

  # ===========================================================================
  # Correlation
  # ===========================================================================

  describe "correlate/2" do
    test "defaults to pearson" do
      assert {:error, :nif_not_loaded} = Stats.correlate([1.0, 2.0], [3.0, 4.0])
    end

    test "rejects non-list x" do
      assert_raise FunctionClauseError, fn -> Stats.correlate("not", [1.0]) end
    end

    test "rejects non-list y" do
      assert_raise FunctionClauseError, fn -> Stats.correlate([1.0], "not") end
    end
  end

  describe "correlate/3 with opts" do
    test "accepts method: :pearson" do
      assert {:error, :nif_not_loaded} = Stats.correlate([1.0, 2.0], [3.0, 4.0], method: :pearson)
    end

    test "accepts method: :spearman" do
      assert {:error, :nif_not_loaded} = Stats.correlate([1.0, 2.0], [3.0, 4.0], method: :spearman)
    end
  end

  # ===========================================================================
  # Hypothesis testing
  # ===========================================================================

  describe "t_test/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Stats.t_test([1.0, 2.0, 3.0])
    end

    test "accepts mu option" do
      assert {:error, :nif_not_loaded} = Stats.t_test([1.0, 2.0, 3.0], mu: 5.0)
    end

    test "rejects non-list" do
      assert_raise FunctionClauseError, fn -> Stats.t_test("not a list") end
    end
  end

  describe "t_test_two/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Stats.t_test_two([1.0, 2.0], [3.0, 4.0])
    end

    test "accepts equal_var option" do
      assert {:error, :nif_not_loaded} = Stats.t_test_two([1.0, 2.0], [3.0, 4.0], equal_var: true)
    end

    test "rejects non-list x" do
      assert_raise FunctionClauseError, fn -> Stats.t_test_two("not", [1.0]) end
    end
  end

  describe "mann_whitney/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Stats.mann_whitney([1.0, 2.0], [3.0, 4.0])
    end

    test "rejects non-list" do
      assert_raise FunctionClauseError, fn -> Stats.mann_whitney("not", [1.0]) end
    end
  end

  # ===========================================================================
  # P-value adjustment
  # ===========================================================================

  describe "adjust/1" do
    test "defaults to bonferroni" do
      assert {:error, :nif_not_loaded} = Stats.adjust([0.01, 0.05])
    end

    test "rejects non-list" do
      assert_raise FunctionClauseError, fn -> Stats.adjust("not a list") end
    end
  end

  describe "adjust/2 with opts" do
    test "accepts method: :bonferroni" do
      assert {:error, :nif_not_loaded} = Stats.adjust([0.01, 0.05], method: :bonferroni)
    end

    test "accepts method: :bh" do
      assert {:error, :nif_not_loaded} = Stats.adjust([0.01, 0.05], method: :bh)
    end
  end

  # ===========================================================================
  # Effect sizes
  # ===========================================================================

  describe "cohens_d/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Stats.cohens_d([1.0, 2.0, 3.0], [4.0, 5.0, 6.0])
    end

    test "rejects non-list group1" do
      assert_raise FunctionClauseError, fn -> Stats.cohens_d("not", [1.0]) end
    end

    test "rejects non-list group2" do
      assert_raise FunctionClauseError, fn -> Stats.cohens_d([1.0], "not") end
    end
  end

  describe "odds_ratio/4" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Stats.odds_ratio(10, 20, 30, 40)
    end

    test "rejects non-integer a" do
      assert_raise FunctionClauseError, fn -> Stats.odds_ratio("10", 20, 30, 40) end
    end
  end

  # ===========================================================================
  # Distributions
  # ===========================================================================

  describe "normal_cdf/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Stats.normal_cdf(1.96)
    end

    test "accepts mu and sigma options" do
      assert {:error, :nif_not_loaded} = Stats.normal_cdf(1.96, mu: 0.0, sigma: 1.0)
    end

    test "rejects non-number x" do
      assert_raise FunctionClauseError, fn -> Stats.normal_cdf("1.96") end
    end
  end

  describe "normal_pdf/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Stats.normal_pdf(0.0)
    end

    test "accepts mu and sigma options" do
      assert {:error, :nif_not_loaded} = Stats.normal_pdf(0.0, mu: 0.0, sigma: 1.0)
    end

    test "rejects non-number x" do
      assert_raise FunctionClauseError, fn -> Stats.normal_pdf("0.0") end
    end
  end

  describe "chi_squared_cdf/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Stats.chi_squared_cdf(3.84, 1)
    end

    test "rejects non-number x" do
      assert_raise FunctionClauseError, fn -> Stats.chi_squared_cdf("3.84", 1) end
    end

    test "rejects non-number df" do
      assert_raise FunctionClauseError, fn -> Stats.chi_squared_cdf(3.84, "1") end
    end
  end

  # ===========================================================================
  # Bayesian
  # ===========================================================================

  describe "bayesian_update/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Stats.bayesian_update(:beta,
        alpha: 1.0, beta: 1.0, successes: 7, trials: 10
      )
    end

    test "raises on missing required key" do
      assert_raise KeyError, fn ->
        Stats.bayesian_update(:beta, alpha: 1.0, beta: 1.0, successes: 7)
      end
    end
  end
end
