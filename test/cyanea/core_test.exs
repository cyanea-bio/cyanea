defmodule Cyanea.CoreTest do
  use ExUnit.Case, async: false

  alias Cyanea.Core

  describe "sha256/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Core.sha256("hello")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Core.sha256(123) end
    end
  end

  describe "sha256_file/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Core.sha256_file("/tmp/test.txt")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Core.sha256_file(123) end
    end
  end

  describe "zstd_compress/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Core.zstd_compress("hello")
    end

    test "accepts level option" do
      assert {:error, :nif_not_loaded} = Core.zstd_compress("hello", level: 10)
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Core.zstd_compress(123) end
    end
  end

  describe "zstd_decompress/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Core.zstd_decompress(<<0, 1, 2>>)
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Core.zstd_decompress(123) end
    end
  end

  describe "gzip_compress/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Core.gzip_compress("hello")
    end

    test "accepts level option" do
      assert {:error, :nif_not_loaded} = Core.gzip_compress("hello", level: 9)
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Core.gzip_compress(123) end
    end
  end

  describe "gzip_decompress/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Core.gzip_decompress(<<0, 1, 2>>)
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Core.gzip_decompress(123) end
    end
  end
end
