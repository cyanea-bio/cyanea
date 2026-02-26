defmodule CyaneaWeb.ContentHelpersTest do
  use Cyanea.DataCase, async: false

  alias CyaneaWeb.ContentHelpers
  alias Phoenix.LiveView.Socket

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  defp build_socket(user \\ nil) do
    %Socket{assigns: %{current_user: user, flash: %{}, __changed__: %{}}}
  end

  describe "mount_space/2" do
    test "loads a public space for anonymous users" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})

      {:ok, socket} =
        ContentHelpers.mount_space(build_socket(), %{
          "username" => user.username,
          "slug" => space.slug
        })

      assert socket.assigns.space.id == space.id
      assert socket.assigns.owner_name == user.username
      assert socket.assigns.is_owner == false
    end

    test "sets is_owner for space owner" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})

      {:ok, socket} =
        ContentHelpers.mount_space(build_socket(user), %{
          "username" => user.username,
          "slug" => space.slug
        })

      assert socket.assigns.is_owner == true
    end

    test "returns error for nonexistent space" do
      {:error, socket} =
        ContentHelpers.mount_space(build_socket(), %{
          "username" => "nobody",
          "slug" => "nonexistent"
        })

      assert socket.redirected
    end

    test "returns error when anonymous user accesses private space" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})

      {:error, socket} =
        ContentHelpers.mount_space(build_socket(), %{
          "username" => user.username,
          "slug" => space.slug
        })

      assert socket.redirected
    end

    test "allows owner to access private space" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})

      {:ok, socket} =
        ContentHelpers.mount_space(build_socket(user), %{
          "username" => user.username,
          "slug" => space.slug
        })

      assert socket.assigns.space.id == space.id
      assert socket.assigns.is_owner == true
    end
  end
end
