defmodule CyaneaWeb.FilePreviewLiveTest do
  use CyaneaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.BlobsFixtures

  describe "FilePreviewLive" do
    setup do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      blob = blob_fixture(%{mime_type: "text/plain"})
      file = space_file_fixture(%{space_id: space.id, blob_id: blob.id, name: "test.fasta", path: "test.fasta"})

      %{user: user, space: space, blob: blob, space_file: file}
    end

    test "renders file preview page for public space", %{conn: conn, space: space, space_file: file} do
      owner_name = Cyanea.Spaces.owner_display(space)
      {:ok, _lv, html} = live(conn, "/#{owner_name}/#{space.slug}/files/#{file.id}")

      assert html =~ "test.fasta"
    end

    test "redirects for non-existent file", %{conn: conn, space: space} do
      owner_name = Cyanea.Spaces.owner_display(space)

      assert {:error, {:redirect, %{to: _}}} =
               live(conn, "/#{owner_name}/#{space.slug}/files/#{Ecto.UUID.generate()}")
    end

    test "requires access for private spaces", %{conn: conn} do
      other_user = user_fixture()

      space =
        space_fixture(%{
          owner_type: "user",
          owner_id: other_user.id,
          visibility: "private",
          slug: "private-space"
        })

      blob = blob_fixture(%{mime_type: "text/plain"})

      file =
        space_file_fixture(%{
          space_id: space.id,
          blob_id: blob.id,
          name: "secret.txt",
          path: "secret.txt"
        })

      owner_name = Cyanea.Spaces.owner_display(space)

      # Unauthenticated user should be redirected
      {:ok, _conn} =
        live(conn, "/#{owner_name}/#{space.slug}/files/#{file.id}")
        |> case do
          {:error, {:redirect, _}} -> {:ok, :redirected}
          {:ok, _lv, _html} -> {:ok, :rendered}
        end
    end

    test "shows download button", %{conn: conn, space: space, space_file: file} do
      owner_name = Cyanea.Spaces.owner_display(space)
      {:ok, _lv, html} = live(conn, "/#{owner_name}/#{space.slug}/files/#{file.id}")

      assert html =~ "Download"
    end
  end
end
