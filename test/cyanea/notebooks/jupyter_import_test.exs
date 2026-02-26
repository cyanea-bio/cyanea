defmodule Cyanea.Notebooks.JupyterImportTest do
  use ExUnit.Case, async: false

  alias Cyanea.Notebooks.JupyterImport

  @valid_notebook Jason.encode!(%{
    nbformat: 4,
    nbformat_minor: 5,
    metadata: %{
      kernelspec: %{display_name: "Python 3", name: "python3"},
      language_info: %{name: "python"}
    },
    cells: [
      %{
        cell_type: "markdown",
        source: ["# My Notebook\n", "Some description"],
        metadata: %{}
      },
      %{
        cell_type: "code",
        source: ["import numpy as np\n", "x = np.array([1, 2, 3])"],
        metadata: %{},
        outputs: []
      },
      %{
        cell_type: "code",
        source: ["print(x)"],
        metadata: %{},
        outputs: [%{output_type: "stream", text: ["[1 2 3]\n"]}]
      },
      %{
        cell_type: "raw",
        source: ["Some raw text"],
        metadata: %{}
      }
    ]
  })

  describe "parse/1" do
    test "parses a valid notebook" do
      {:ok, result} = JupyterImport.parse(@valid_notebook)

      assert result.title == "My Notebook"
      assert length(result.content["cells"]) == 4
      assert result.metadata["imported_from"] == "jupyter"
      assert result.metadata["nbformat"] == 4
      assert result.metadata["language"] == "python"
    end

    test "converts cell types correctly" do
      {:ok, result} = JupyterImport.parse(@valid_notebook)
      cells = result.content["cells"]

      # First cell: markdown
      assert Enum.at(cells, 0)["type"] == "markdown"
      assert Enum.at(cells, 0)["source"] =~ "My Notebook"

      # Second cell: code
      assert Enum.at(cells, 1)["type"] == "code"
      assert Enum.at(cells, 1)["source"] =~ "import numpy"
      assert Enum.at(cells, 1)["language"] == "cyanea"

      # Third cell: code
      assert Enum.at(cells, 2)["type"] == "code"

      # Fourth cell: raw → markdown
      assert Enum.at(cells, 3)["type"] == "markdown"
      assert Enum.at(cells, 3)["source"] == "Some raw text"
    end

    test "assigns sequential positions" do
      {:ok, result} = JupyterImport.parse(@valid_notebook)
      positions = Enum.map(result.content["cells"], & &1["position"])
      assert positions == [0, 1, 2, 3]
    end

    test "generates unique cell IDs" do
      {:ok, result} = JupyterImport.parse(@valid_notebook)
      ids = Enum.map(result.content["cells"], & &1["id"])
      assert length(Enum.uniq(ids)) == length(ids)
    end

    test "extracts title from first heading" do
      notebook = Jason.encode!(%{
        nbformat: 4,
        metadata: %{},
        cells: [
          %{cell_type: "markdown", source: ["Some text\n", "# First Heading\n"]},
          %{cell_type: "code", source: ["x = 1"]}
        ]
      })

      {:ok, result} = JupyterImport.parse(notebook)
      assert result.title == "First Heading"
    end

    test "falls back to kernel display name" do
      notebook = Jason.encode!(%{
        nbformat: 4,
        metadata: %{kernelspec: %{display_name: "Julia 1.8"}},
        cells: [%{cell_type: "code", source: ["x = 1"]}]
      })

      {:ok, result} = JupyterImport.parse(notebook)
      assert result.title == "Julia 1.8"
    end

    test "falls back to default title" do
      notebook = Jason.encode!(%{
        nbformat: 4,
        metadata: %{},
        cells: [%{cell_type: "code", source: ["x = 1"]}]
      })

      {:ok, result} = JupyterImport.parse(notebook)
      assert result.title == "Imported Notebook"
    end

    test "rejects nbformat < 4" do
      notebook = Jason.encode!(%{nbformat: 3, cells: []})
      assert {:error, "Only nbformat 4.x is supported"} = JupyterImport.parse(notebook)
    end

    test "rejects invalid JSON" do
      assert {:error, _} = JupyterImport.parse("not json")
    end

    test "rejects missing nbformat" do
      notebook = Jason.encode!(%{cells: []})
      assert {:error, "Invalid Jupyter notebook format: missing nbformat"} = JupyterImport.parse(notebook)
    end

    test "rejects non-string input" do
      assert {:error, "Expected a JSON string"} = JupyterImport.parse(123)
    end

    test "handles source as string instead of list" do
      notebook = Jason.encode!(%{
        nbformat: 4,
        metadata: %{},
        cells: [%{cell_type: "code", source: "x = 1"}]
      })

      {:ok, result} = JupyterImport.parse(notebook)
      assert hd(result.content["cells"])["source"] == "x = 1"
    end
  end
end
