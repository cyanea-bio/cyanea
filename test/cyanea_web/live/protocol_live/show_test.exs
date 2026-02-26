defmodule CyaneaWeb.ProtocolLive.ShowTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.SpacesFixtures
  import Cyanea.ProtocolsFixtures

  setup :register_and_log_in_user

  setup %{user: user} do
    space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})

    protocol =
      protocol_fixture(%{
        space_id: space.id,
        title: "PCR Protocol",
        slug: "pcr-protocol",
        content: %{
          "materials" => [
            %{
              "name" => "Taq Polymerase",
              "quantity" => "1 uL",
              "vendor" => "NEB",
              "catalog_number" => "M0273"
            }
          ],
          "equipment" => [
            %{"name" => "Thermocycler", "settings" => "Standard", "notes" => ""}
          ],
          "steps" => [
            %{
              "number" => 1,
              "description" => "Prepare master mix",
              "duration" => "5 min",
              "temperature" => "4C",
              "notes" => "Keep on ice"
            }
          ],
          "tips" => "Increase template if bands are faint."
        }
      })

    %{space: space, protocol: protocol}
  end

  describe "owner view" do
    test "shows protocol with all sections", %{conn: conn, user: user, space: space} do
      {:ok, _view, html} = live(conn, ~p"/#{user.username}/#{space.slug}/protocols/pcr-protocol")
      assert html =~ "PCR Protocol"
      assert html =~ "v1.0.0"
      assert html =~ "Taq Polymerase"
      assert html =~ "Thermocycler"
      assert html =~ "Prepare master mix"
      assert html =~ "Increase template if bands are faint."
    end

    test "can edit materials section", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/protocols/pcr-protocol")

      # Click edit on materials
      html = render_click(view, "edit-section", %{"section" => "materials"})
      assert html =~ "Taq Polymerase"
    end

    test "can save materials", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/protocols/pcr-protocol")
      render_click(view, "edit-section", %{"section" => "materials"})

      html =
        render_submit(view, "save-materials", %{
          "materials" => %{
            "0" => %{
              "name" => "New Enzyme",
              "quantity" => "2 uL",
              "vendor" => "Promega",
              "catalog_number" => "X123"
            }
          }
        })

      assert html =~ "New Enzyme"
    end

    test "bump patch version", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/protocols/pcr-protocol")

      html = render_click(view, "bump-version", %{"level" => "patch"})
      assert html =~ "v1.0.1"
    end

    test "bump minor version", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/protocols/pcr-protocol")

      html = render_click(view, "bump-version", %{"level" => "minor"})
      assert html =~ "v1.1.0"
    end
  end

  describe "viewer (read-only)" do
    test "anonymous user sees rendered content", %{space: space, user: user} do
      conn = build_conn()
      {:ok, _view, html} = live(conn, ~p"/#{user.username}/#{space.slug}/protocols/pcr-protocol")
      assert html =~ "PCR Protocol"
      assert html =~ "Taq Polymerase"
      assert html =~ "Prepare master mix"
      # No edit buttons for anonymous
      refute html =~ "Bump patch"
    end
  end
end
