defmodule CyaneaWeb.ExploreLiveTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.DatasetsFixtures

  describe "Explore page" do
    test "lists public spaces", %{conn: conn} do
      user = user_fixture()

      _space =
        space_fixture(%{
          owner_type: "user",
          owner_id: user.id,
          visibility: "public",
          name: "public-data"
        })

      {:ok, _lv, html} = live(conn, ~p"/explore")
      assert html =~ "public-data"
    end

    test "hides private spaces", %{conn: conn} do
      user = user_fixture()

      _private =
        space_fixture(%{
          owner_type: "user",
          owner_id: user.id,
          visibility: "private",
          name: "secret-data"
        })

      {:ok, _lv, html} = live(conn, ~p"/explore")
      refute html =~ "secret-data"
    end

    test "shows a download badge and supports the most-downloaded sort", %{conn: conn} do
      user = user_fixture()

      space =
        space_fixture(%{
          owner_type: "user",
          owner_id: user.id,
          visibility: "public",
          name: "downloaded-data"
        })

      dataset = dataset_fixture(%{space_id: space.id})
      for _ <- 1..4, do: Cyanea.Datasets.increment_download_count(dataset.id)

      {:ok, lv, html} = live(conn, ~p"/explore")

      # Download badge (hero-arrow-down-tray) only renders when a space has downloads.
      assert html =~ "downloaded-data"
      assert html =~ "hero-arrow-down-tray"
      assert html =~ "Most downloaded"

      # Sorting by most-downloaded still returns the space.
      html2 = render_click(lv, "sort", %{"sort" => "most_downloaded"})
      assert html2 =~ "downloaded-data"
    end

    test "no download badge when a space has no downloads", %{conn: conn} do
      user = user_fixture()

      _space =
        space_fixture(%{
          owner_type: "user",
          owner_id: user.id,
          visibility: "public",
          name: "plain-data"
        })

      {:ok, _lv, html} = live(conn, ~p"/explore")
      assert html =~ "plain-data"
      refute html =~ "hero-arrow-down-tray"
    end
  end
end
