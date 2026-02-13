defmodule Cyanea.MLTest do
  use ExUnit.Case, async: true

  alias Cyanea.ML

  # ===========================================================================
  # Clustering
  # ===========================================================================

  describe "kmeans/3" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.kmeans([0.0, 0.0, 1.0, 1.0], 2, 2)
    end

    test "accepts keyword opts" do
      assert {:error, :nif_not_loaded} = ML.kmeans([0.0, 0.0, 1.0, 1.0], 2, 2, max_iter: 50, seed: 123)
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.kmeans("not", 2, 2) end
    end

    test "rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> ML.kmeans([1.0], "2", 2) end
    end

    test "rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> ML.kmeans([1.0], 2, "2") end
    end
  end

  describe "dbscan/4" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.dbscan([0.0, 0.0, 1.0, 1.0], 2, 0.5, 2)
    end

    test "accepts atom metric" do
      assert {:error, :nif_not_loaded} = ML.dbscan([0.0, 0.0], 2, 0.5, 2, metric: :cosine)
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.dbscan("not", 2, 0.5, 2) end
    end

    test "rejects non-number eps" do
      assert_raise FunctionClauseError, fn -> ML.dbscan([1.0], 1, "bad", 2) end
    end

    test "rejects non-integer min_samples" do
      assert_raise FunctionClauseError, fn -> ML.dbscan([1.0], 1, 0.5, "2") end
    end
  end

  describe "hierarchical/3" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.hierarchical([0.0, 0.0, 1.0, 1.0], 2, 2)
    end

    test "accepts atom linkage and metric" do
      assert {:error, :nif_not_loaded} = ML.hierarchical([0.0, 0.0, 1.0, 1.0], 2, 2,
        linkage: :single, metric: :manhattan
      )
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.hierarchical("not", 2, 2) end
    end

    test "rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> ML.hierarchical([1.0], "2", 2) end
    end

    test "rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> ML.hierarchical([1.0], 2, "2") end
    end
  end

  # ===========================================================================
  # Dimensionality reduction
  # ===========================================================================

  describe "pca/3" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.pca([1.0, 2.0, 3.0, 4.0], 2, 1)
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.pca("not", 2, 1) end
    end

    test "rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> ML.pca([1.0], "2", 1) end
    end

    test "rejects non-integer n_components" do
      assert_raise FunctionClauseError, fn -> ML.pca([1.0], 2, "1") end
    end
  end

  describe "tsne/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.tsne([1.0, 2.0, 3.0, 4.0], 2)
    end

    test "accepts keyword opts" do
      assert {:error, :nif_not_loaded} = ML.tsne([1.0, 2.0, 3.0, 4.0], 2,
        n_components: 2, perplexity: 5.0, n_iter: 100
      )
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.tsne("not", 2) end
    end

    test "rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> ML.tsne([1.0], "2") end
    end
  end

  describe "umap/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.umap([1.0, 2.0, 3.0, 4.0], 2)
    end

    test "accepts keyword opts" do
      assert {:error, :nif_not_loaded} = ML.umap([1.0, 2.0, 3.0, 4.0], 2,
        n_components: 2, n_neighbors: 15, min_dist: 0.1, n_epochs: 200, metric: :euclidean, seed: 42
      )
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.umap("not", 2) end
    end
  end

  # ===========================================================================
  # Embeddings & distances
  # ===========================================================================

  describe "embed/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.embed("ATCGATCG", 3)
    end

    test "accepts atom alphabet" do
      assert {:error, :nif_not_loaded} = ML.embed("MVLKGAA", 2, alphabet: :protein)
    end

    test "rejects non-binary sequence" do
      assert_raise FunctionClauseError, fn -> ML.embed(123, 3) end
    end

    test "rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> ML.embed("ATCG", "3") end
    end
  end

  describe "batch_embed/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.batch_embed(["ATCG", "GCTA"], 3)
    end

    test "accepts atom alphabet" do
      assert {:error, :nif_not_loaded} = ML.batch_embed(["ATCG", "GCTA"], 3, alphabet: :dna)
    end

    test "rejects non-list sequences" do
      assert_raise FunctionClauseError, fn -> ML.batch_embed("not", 3) end
    end

    test "rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> ML.batch_embed(["ATCG"], "3") end
    end
  end

  describe "distances/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.distances([0.0, 0.0, 1.0, 1.0], 2)
    end

    test "accepts atom metric" do
      assert {:error, :nif_not_loaded} = ML.distances([0.0, 0.0], 2, metric: :manhattan)
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.distances("not", 2) end
    end

    test "rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> ML.distances([1.0], "2") end
    end
  end

  # ===========================================================================
  # Classification & Regression
  # ===========================================================================

  describe "knn/5" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.knn(
        [0.0, 0.0, 1.0, 1.0], 2, 1, [0, 1], [0.5, 0.5]
      )
    end

    test "accepts atom metric" do
      assert {:error, :nif_not_loaded} = ML.knn(
        [0.0, 0.0, 1.0, 1.0], 2, 1, [0, 1], [0.5, 0.5], metric: :euclidean
      )
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.knn("not", 2, 1, [0], [0.5]) end
    end

    test "rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> ML.knn([1.0], 2, "1", [0], [0.5]) end
    end

    test "rejects non-list labels" do
      assert_raise FunctionClauseError, fn -> ML.knn([1.0], 2, 1, "not", [0.5]) end
    end

    test "rejects non-list query" do
      assert_raise FunctionClauseError, fn -> ML.knn([1.0], 2, 1, [0], "not") end
    end
  end

  describe "fit_linear/3" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.fit_linear([1.0, 2.0, 3.0, 4.0], 2, [1.0, 2.0])
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.fit_linear("not", 2, [1.0]) end
    end

    test "rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> ML.fit_linear([1.0], "2", [1.0]) end
    end

    test "rejects non-list targets" do
      assert_raise FunctionClauseError, fn -> ML.fit_linear([1.0], 2, "not") end
    end
  end

  describe "predict_linear/4" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.predict_linear([0.5, 0.3], 0.1, [1.0, 2.0], 2)
    end

    test "rejects non-list weights" do
      assert_raise FunctionClauseError, fn -> ML.predict_linear("not", 0.1, [1.0], 2) end
    end

    test "rejects non-number bias" do
      assert_raise FunctionClauseError, fn -> ML.predict_linear([0.5], "0.1", [1.0], 2) end
    end

    test "rejects non-list queries" do
      assert_raise FunctionClauseError, fn -> ML.predict_linear([0.5], 0.1, "not", 2) end
    end

    test "rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> ML.predict_linear([0.5], 0.1, [1.0], "2") end
    end
  end

  describe "fit_forest/3" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.fit_forest([1.0, 2.0, 3.0, 4.0], 2, [0, 1])
    end

    test "accepts keyword opts" do
      assert {:error, :nif_not_loaded} = ML.fit_forest([1.0, 2.0, 3.0, 4.0], 2, [0, 1],
        n_trees: 20, max_depth: 10, seed: 99
      )
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.fit_forest("not", 2, [0]) end
    end

    test "rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> ML.fit_forest([1.0], "2", [0]) end
    end

    test "rejects non-list labels" do
      assert_raise FunctionClauseError, fn -> ML.fit_forest([1.0], 2, "not") end
    end
  end

  describe "predict_forest/3" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.predict_forest(<<0, 1, 2>>, [1.0, 2.0], 2)
    end

    test "rejects non-binary model" do
      assert_raise FunctionClauseError, fn -> ML.predict_forest(123, [1.0], 2) end
    end

    test "rejects non-list sample" do
      assert_raise FunctionClauseError, fn -> ML.predict_forest(<<0>>, "not", 2) end
    end

    test "rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> ML.predict_forest(<<0>>, [1.0], "2") end
    end
  end

  # ===========================================================================
  # HMM
  # ===========================================================================

  describe "hmm_viterbi/6" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.hmm_viterbi(
        2, 2,
        [0.5, 0.5],
        [0.7, 0.3, 0.4, 0.6],
        [0.9, 0.1, 0.2, 0.8],
        [0, 1, 0]
      )
    end

    test "rejects non-integer n_states" do
      assert_raise FunctionClauseError, fn ->
        ML.hmm_viterbi("2", 2, [0.5], [0.5], [0.5], [0])
      end
    end

    test "rejects non-list initial" do
      assert_raise FunctionClauseError, fn ->
        ML.hmm_viterbi(2, 2, "not", [0.5], [0.5], [0])
      end
    end
  end

  describe "hmm_forward/6" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.hmm_forward(
        2, 2,
        [0.5, 0.5],
        [0.7, 0.3, 0.4, 0.6],
        [0.9, 0.1, 0.2, 0.8],
        [0, 1, 0]
      )
    end

    test "rejects non-integer n_symbols" do
      assert_raise FunctionClauseError, fn ->
        ML.hmm_forward(2, "2", [0.5], [0.5], [0.5], [0])
      end
    end

    test "rejects non-list observations" do
      assert_raise FunctionClauseError, fn ->
        ML.hmm_forward(2, 2, [0.5], [0.5], [0.5], "not")
      end
    end
  end

  # ===========================================================================
  # Normalization & evaluation
  # ===========================================================================

  describe "normalize/2" do
    test "min_max returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.normalize([1.0, 2.0, 3.0], :min_max)
    end

    test "z_score returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.normalize([1.0, 2.0, 3.0], :z_score)
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.normalize("not", :min_max) end
    end
  end

  describe "silhouette/3" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = ML.silhouette(
        [0.0, 0.0, 1.0, 1.0, 5.0, 5.0], 2, [0, 0, 1]
      )
    end

    test "accepts atom metric" do
      assert {:error, :nif_not_loaded} = ML.silhouette(
        [0.0, 0.0, 1.0, 1.0], 2, [0, 1], metric: :cosine
      )
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> ML.silhouette("not", 2, [0]) end
    end

    test "rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> ML.silhouette([1.0], "2", [0]) end
    end

    test "rejects non-list labels" do
      assert_raise FunctionClauseError, fn -> ML.silhouette([1.0], 2, "not") end
    end
  end
end
