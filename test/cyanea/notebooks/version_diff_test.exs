defmodule Cyanea.Notebooks.VersionDiffTest do
  use ExUnit.Case, async: false

  alias Cyanea.Notebooks.VersionDiff

  @cell1 %{"id" => "c1", "type" => "markdown", "source" => "# Hello", "position" => 0}
  @cell2 %{"id" => "c2", "type" => "code", "language" => "cyanea", "source" => "Seq.gc()", "position" => 1}
  @cell3 %{"id" => "c3", "type" => "code", "language" => "elixir", "source" => "1 + 1", "position" => 2}

  describe "diff/2" do
    test "identical content returns all unchanged" do
      content = %{"cells" => [@cell1, @cell2]}
      changes = VersionDiff.diff(content, content)

      assert length(changes) == 2
      assert Enum.all?(changes, &(&1.type == :unchanged))
    end

    test "detects modified cells" do
      old = %{"cells" => [@cell1]}
      new = %{"cells" => [%{@cell1 | "source" => "# Updated"}]}

      [change] = VersionDiff.diff(old, new)
      assert change.type == :modified
      assert change.old_source == "# Hello"
      assert change.new_source == "# Updated"
    end

    test "detects added cells" do
      old = %{"cells" => [@cell1]}
      new = %{"cells" => [@cell1, @cell2]}

      changes = VersionDiff.diff(old, new)
      added = Enum.filter(changes, &(&1.type == :added))
      assert length(added) == 1
      assert hd(added).cell_id == "c2"
    end

    test "detects removed cells" do
      old = %{"cells" => [@cell1, @cell2]}
      new = %{"cells" => [@cell1]}

      changes = VersionDiff.diff(old, new)
      removed = Enum.filter(changes, &(&1.type == :removed))
      assert length(removed) == 1
      assert hd(removed).cell_id == "c2"
    end

    test "detects moved cells" do
      old = %{"cells" => [@cell1, @cell2]}
      new = %{"cells" => [%{@cell2 | "position" => 0}, %{@cell1 | "position" => 1}]}

      changes = VersionDiff.diff(old, new)
      moved = Enum.filter(changes, &(&1.type == :moved))
      assert length(moved) == 2
    end

    test "handles empty old content" do
      old = %{"cells" => []}
      new = %{"cells" => [@cell1, @cell2]}

      changes = VersionDiff.diff(old, new)
      assert length(changes) == 2
      assert Enum.all?(changes, &(&1.type == :added))
    end

    test "handles empty new content" do
      old = %{"cells" => [@cell1, @cell2]}
      new = %{"cells" => []}

      changes = VersionDiff.diff(old, new)
      assert length(changes) == 2
      assert Enum.all?(changes, &(&1.type == :removed))
    end

    test "handles missing cells key" do
      assert VersionDiff.diff(%{}, %{}) == []
    end

    test "complex diff with multiple change types" do
      old = %{"cells" => [@cell1, @cell2, @cell3]}

      new = %{
        "cells" => [
          @cell1,
          %{@cell2 | "source" => "Seq.gc(\"ATGC\")"},
          %{"id" => "c4", "type" => "markdown", "source" => "New cell", "position" => 2}
        ]
      }

      changes = VersionDiff.diff(old, new)

      unchanged = Enum.filter(changes, &(&1.type == :unchanged))
      modified = Enum.filter(changes, &(&1.type == :modified))
      added = Enum.filter(changes, &(&1.type == :added))
      removed = Enum.filter(changes, &(&1.type == :removed))

      assert length(unchanged) == 1
      assert length(modified) == 1
      assert length(added) == 1
      assert length(removed) == 1
    end
  end
end
