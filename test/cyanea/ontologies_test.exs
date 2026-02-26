defmodule Cyanea.OntologiesTest do
  use ExUnit.Case, async: false

  alias Cyanea.Ontologies

  describe "ontology_sources/0" do
    test "returns list of known ontology sources" do
      sources = Ontologies.ontology_sources()

      assert is_list(sources)
      assert length(sources) > 0

      ids = Enum.map(sources, & &1.id)
      assert "go" in ids
      assert "efo" in ids
      assert "ncbitaxon" in ids
    end

    test "each source has id and name" do
      for source <- Ontologies.ontology_sources() do
        assert is_binary(source.id)
        assert is_binary(source.name)
        assert source.id != ""
        assert source.name != ""
      end
    end
  end

  describe "format_ontology_term/1" do
    test "normalizes atom-key map" do
      term = %{id: "GO:0008150", label: "biological_process", source: "go", uri: "http://example.com"}
      result = Ontologies.format_ontology_term(term)

      assert result.id == "GO:0008150"
      assert result.label == "biological_process"
      assert result.source == "go"
      assert result.uri == "http://example.com"
    end

    test "normalizes string-key map" do
      term = %{"id" => "EFO:0001234", "label" => "some term", "source" => "efo"}
      result = Ontologies.format_ontology_term(term)

      assert result.id == "EFO:0001234"
      assert result.label == "some term"
      assert result.source == "efo"
      assert result.uri == ""
    end

    test "handles minimal map" do
      result = Ontologies.format_ontology_term(%{})

      assert result.id == ""
      assert result.label == ""
      assert result.source == ""
      assert result.uri == ""
    end
  end

  describe "search_terms/2" do
    test "returns empty list for blank query" do
      assert {:ok, []} = Ontologies.search_terms("")
      assert {:ok, []} = Ontologies.search_terms("   ")
    end
  end

  describe "search_organisms/1" do
    test "returns empty list for blank query" do
      assert {:ok, []} = Ontologies.search_organisms("")
      assert {:ok, []} = Ontologies.search_organisms("   ")
    end
  end
end
