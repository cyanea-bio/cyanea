defmodule CyaneaWeb.DatasetLive.ShowTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.SpacesFixtures
  import Cyanea.DatasetsFixtures

  setup :register_and_log_in_user

  setup %{user: user} do
    space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})

    dataset =
      dataset_fixture(%{
        space_id: space.id,
        name: "RNA-seq Counts",
        slug: "rna-seq-counts",
        tags: ["genomics", "rna-seq"],
        metadata: %{
          "row_count" => 1000,
          "column_count" => 5,
          "columns" => ["gene_id", "sample_1", "sample_2", "sample_3", "p_value"]
        }
      })

    %{space: space, dataset: dataset}
  end

  describe "owner view" do
    test "shows dataset with file upload zone", %{conn: conn, user: user, space: space} do
      {:ok, _view, html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/datasets/rna-seq-counts")

      assert html =~ "RNA-seq Counts"
      assert html =~ "genomics"
      assert html =~ "rna-seq"
    end

    test "preview tab shows CSV stats", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/datasets/rna-seq-counts")

      html = render_click(view, "switch-tab", %{"tab" => "preview"})
      assert html =~ "CSV Statistics"
      assert html =~ "1000"
    end

    test "metadata tab shows dataset info", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/datasets/rna-seq-counts")

      html = render_click(view, "switch-tab", %{"tab" => "metadata"})
      assert html =~ "Dataset metadata"
      assert html =~ "local"
    end

    test "can edit metadata", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/datasets/rna-seq-counts")

      render_click(view, "switch-tab", %{"tab" => "metadata"})
      render_click(view, "edit-metadata")

      html =
        render_submit(view, "save-metadata", %{
          "description" => "Updated description",
          "tags" => "proteomics, human"
        })

      assert html =~ "Updated description" or html =~ "Metadata saved"
    end
  end

  describe "viewer (read-only)" do
    test "anonymous user sees dataset info", %{space: space, user: user} do
      conn = build_conn()

      {:ok, _view, html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/datasets/rna-seq-counts")

      assert html =~ "RNA-seq Counts"
      # No upload form for anonymous (owner-only feature)
      refute html =~ "phx-submit=\"upload\""
    end
  end
end
