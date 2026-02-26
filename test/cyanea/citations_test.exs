defmodule Cyanea.CitationsTest do
  use Cyanea.DataCase

  alias Cyanea.Citations

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  defp create_space_with_owner(_ctx \\ %{}) do
    user = user_fixture()

    space =
      space_fixture(%{
        owner_type: "user",
        owner_id: user.id,
        name: "My Research Space",
        slug: "my-research-space",
        description: "A test research space",
        visibility: "public",
        license: "cc-by-4.0",
        tags: ["genomics", "rna-seq"],
        ontology_terms: [%{"id" => "GO:0008150", "label" => "biological_process", "source" => "go"}]
      })

    %{user: user, space: space}
  end

  describe "cite/2" do
    test "generates valid BibTeX" do
      %{space: space} = create_space_with_owner()
      bibtex = Citations.cite(space, :bibtex)

      assert String.contains?(bibtex, "@misc{cyanea:my-research-space")
      assert String.contains?(bibtex, "title = {My Research Space}")
      assert String.contains?(bibtex, "publisher = {Cyanea}")
      assert String.contains?(bibtex, "url = {")
    end

    test "generates valid RIS" do
      %{space: space} = create_space_with_owner()
      ris = Citations.cite(space, :ris)

      assert String.contains?(ris, "TY  - DATA")
      assert String.contains?(ris, "TI  - My Research Space")
      assert String.contains?(ris, "PB  - Cyanea")
      assert String.contains?(ris, "ER  -")
    end

    test "generates valid APA" do
      %{space: space} = create_space_with_owner()
      apa = Citations.cite(space, :apa)

      assert String.contains?(apa, "My Research Space")
      assert String.contains?(apa, "Cyanea")
      assert String.contains?(apa, "(#{Date.utc_today().year})")
    end

    test "includes DOI when present" do
      %{space: space} = create_space_with_owner()
      space = %{space | doi: "10.1234/test.doi"}

      bibtex = Citations.cite(space, :bibtex)
      assert String.contains?(bibtex, "doi = {10.1234/test.doi}")

      ris = Citations.cite(space, :ris)
      assert String.contains?(ris, "DO  - 10.1234/test.doi")

      apa = Citations.cite(space, :apa)
      assert String.contains?(apa, "10.1234/test.doi")
    end
  end

  describe "fair_score/1" do
    test "computes score for a well-configured space" do
      %{space: space} = create_space_with_owner()
      score = Citations.fair_score(space)

      assert is_map(score)
      assert score.total >= 0
      assert score.total <= 100
      assert score.findable >= 0
      assert score.accessible >= 0
      assert score.interoperable >= 0
      assert score.reusable >= 0
      assert score.total == score.findable + score.accessible + score.interoperable + score.reusable
    end

    test "gives higher score to well-described public space" do
      %{space: space} = create_space_with_owner()
      score = Citations.fair_score(space)

      # Public + description + tags + license + ontology terms
      assert score.findable > 0
      assert score.accessible > 0
      assert score.interoperable > 0
    end

    test "gives lower score to minimal space" do
      user = user_fixture()

      space =
        space_fixture(%{
          owner_type: "user",
          owner_id: user.id,
          name: "Bare Space",
          slug: "bare-space",
          visibility: "private"
        })

      score = Citations.fair_score(space)
      assert score.total < 50
    end
  end

  describe "contributors/1" do
    test "returns empty list when no activity" do
      %{space: space} = create_space_with_owner()
      contributors = Citations.contributors(space.id)

      assert is_list(contributors)
    end
  end

  describe "doi_metadata/1" do
    test "builds DataCite-compatible metadata" do
      %{space: space} = create_space_with_owner()
      metadata = Citations.doi_metadata(space)

      assert is_map(metadata)
      assert [%{title: "My Research Space"}] = metadata.titles
      assert [%{name: _}] = metadata.creators
      assert metadata.publisher == "Cyanea"
      assert metadata.publicationYear == space.inserted_at.year
      assert %{resourceTypeGeneral: "Dataset"} = metadata.types
    end

    test "includes description when present" do
      %{space: space} = create_space_with_owner()
      metadata = Citations.doi_metadata(space)

      assert [%{description: "A test research space", descriptionType: "Abstract"}] = metadata.descriptions
    end
  end

  describe "mint_doi/1" do
    test "returns error when DataCite is not configured" do
      %{space: space} = create_space_with_owner()
      assert {:error, :datacite_not_configured} = Citations.mint_doi(space)
    end

    test "returns existing DOI if already minted" do
      %{space: space} = create_space_with_owner()
      space = %{space | doi: "10.1234/existing"}
      assert {:ok, "10.1234/existing"} = Citations.mint_doi(space)
    end
  end
end
