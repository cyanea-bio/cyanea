defmodule Cyanea.GPUTest do
  use ExUnit.Case, async: false

  alias Cyanea.GPU

  describe "info/0" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = GPU.info()
    end
  end

  describe "distances/3" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = GPU.distances([0.0, 0.0, 1.0, 1.0], 2, 2)
    end

    test "accepts atom metric" do
      assert {:error, :nif_not_loaded} = GPU.distances([0.0, 0.0, 1.0, 1.0], 2, 2, metric: :manhattan)
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> GPU.distances("not", 2, 2) end
    end

    test "rejects non-integer n" do
      assert_raise FunctionClauseError, fn -> GPU.distances([1.0], "2", 2) end
    end

    test "rejects non-integer dim" do
      assert_raise FunctionClauseError, fn -> GPU.distances([1.0], 2, "2") end
    end
  end

  describe "matrix_multiply/5" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = GPU.matrix_multiply(
        [1.0, 2.0, 3.0, 4.0],
        [5.0, 6.0, 7.0, 8.0],
        2, 2, 2
      )
    end

    test "rejects non-list a" do
      assert_raise FunctionClauseError, fn -> GPU.matrix_multiply("not", [1.0], 2, 2, 2) end
    end

    test "rejects non-list b" do
      assert_raise FunctionClauseError, fn -> GPU.matrix_multiply([1.0], "not", 2, 2, 2) end
    end

    test "rejects non-integer m" do
      assert_raise FunctionClauseError, fn -> GPU.matrix_multiply([1.0], [1.0], "2", 2, 2) end
    end
  end

  describe "reduce_sum/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = GPU.reduce_sum([1.0, 2.0, 3.0])
    end

    test "rejects non-list" do
      assert_raise FunctionClauseError, fn -> GPU.reduce_sum("not") end
    end
  end

  describe "batch_z_score/3" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = GPU.batch_z_score([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3)
    end

    test "rejects non-list data" do
      assert_raise FunctionClauseError, fn -> GPU.batch_z_score("not", 2, 3) end
    end

    test "rejects non-integer n_rows" do
      assert_raise FunctionClauseError, fn -> GPU.batch_z_score([1.0], "2", 3) end
    end

    test "rejects non-integer n_cols" do
      assert_raise FunctionClauseError, fn -> GPU.batch_z_score([1.0], 2, "3") end
    end
  end
end
