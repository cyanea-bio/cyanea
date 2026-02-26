defmodule Cyanea.Notebooks.ExecutionTest do
  use ExUnit.Case, async: false

  alias Cyanea.Notebooks.Execution

  describe "executable?/1" do
    test "cyanea is executable" do
      assert Execution.executable?("cyanea")
    end

    test "elixir is executable" do
      assert Execution.executable?("elixir")
    end

    test "other languages are not executable" do
      refute Execution.executable?("python")
      refute Execution.executable?("r")
      refute Execution.executable?("bash")
      refute Execution.executable?("sql")
    end
  end

  describe "execution_target/1" do
    test "cyanea targets wasm" do
      assert Execution.execution_target("cyanea") == :wasm
    end

    test "elixir targets server" do
      assert Execution.execution_target("elixir") == :server
    end

    test "other languages target server_coming_soon" do
      assert Execution.execution_target("python") == :server_coming_soon
      assert Execution.execution_target("r") == :server_coming_soon
      assert Execution.execution_target("bash") == :server_coming_soon
    end
  end

  describe "supported_languages/0" do
    test "returns all supported languages" do
      langs = Execution.supported_languages()
      assert "cyanea" in langs
      assert "elixir" in langs
      assert "python" in langs
      assert "r" in langs
      assert "bash" in langs
      assert "sql" in langs
    end
  end

  describe "wasm_languages/0" do
    test "returns only wasm-executable languages" do
      assert Execution.wasm_languages() == ["cyanea"]
    end
  end

  describe "server_languages/0" do
    test "returns server-executable languages" do
      assert Execution.server_languages() == ["elixir"]
    end
  end
end
