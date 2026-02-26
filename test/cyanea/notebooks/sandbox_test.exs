defmodule Cyanea.Notebooks.SandboxTest do
  use ExUnit.Case, async: false

  alias Cyanea.Notebooks.Sandbox

  describe "eval/2" do
    test "evaluates simple expressions" do
      assert {:ok, 42, _} = Sandbox.eval("21 * 2")
    end

    test "evaluates with bindings" do
      assert {:ok, 15, _} = Sandbox.eval("x + y", x: 10, y: 5)
    end

    test "allows Enum operations" do
      assert {:ok, [2, 4, 6], _} = Sandbox.eval("Enum.map([1, 2, 3], & &1 * 2)")
    end

    test "allows Map operations" do
      assert {:ok, %{a: 1}, _} = Sandbox.eval("%{a: 1}")
    end

    test "allows String operations" do
      assert {:ok, "HELLO", _} = Sandbox.eval(~s|String.upcase("hello")|)
    end

    test "allows List operations" do
      assert {:ok, [1, 2, 3], _} = Sandbox.eval("List.flatten([[1, 2], [3]])")
    end

    test "allows Kernel functions" do
      assert {:ok, 3, _} = Sandbox.eval("abs(-3)")
    end

    test "allows Range" do
      assert {:ok, [1, 2, 3, 4, 5], _} = Sandbox.eval("Enum.to_list(1..5)")
    end
  end

  describe "eval/2 blocked modules" do
    test "blocks System" do
      assert {:error, msg} = Sandbox.eval(~s|System.cmd("ls", [])|)
      assert msg =~ "System"
    end

    test "blocks File" do
      assert {:error, msg} = Sandbox.eval(~s|File.read!("/etc/passwd")|)
      assert msg =~ "File"
    end

    test "blocks IO" do
      assert {:error, msg} = Sandbox.eval(~s|IO.puts("hi")|)
      assert msg =~ "IO"
    end

    test "blocks Port" do
      assert {:error, msg} = Sandbox.eval("Port.open({:spawn, \"ls\"}, [])")
      assert msg =~ "Port"
    end

    test "blocks Process" do
      assert {:error, msg} = Sandbox.eval("Process.list()")
      assert msg =~ "Process"
    end

    test "blocks Code" do
      assert {:error, msg} = Sandbox.eval(~s|Code.eval_string("1 + 1")|)
      assert msg =~ "Code"
    end

    test "blocks :os erlang module" do
      assert {:error, msg} = Sandbox.eval(~s|:os.cmd(~c"ls")|)
      assert msg =~ ":os"
    end
  end

  describe "eval/2 error handling" do
    test "returns error for syntax errors" do
      assert {:error, msg} = Sandbox.eval("def foo(")
      assert msg =~ "Syntax error"
    end

    test "returns error for runtime errors" do
      assert {:error, msg} = Sandbox.eval("1 / 0")
      assert msg =~ "ArithmeticError"
    end

    test "returns error for undefined functions" do
      assert {:error, msg} = Sandbox.eval("nonexistent_function()")
      assert msg =~ "CompileError" or msg =~ "undefined"
    end
  end
end
