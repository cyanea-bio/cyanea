defmodule Cyanea.SpacesTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Spaces

  import Cyanea.AccountsFixtures
  import Cyanea.BillingFixtures
  import Cyanea.OrganizationsFixtures
  import Cyanea.SpacesFixtures

  describe "create_space/1" do
    test "creates a user-owned space" do
      user = user_fixture()
      attrs = valid_space_attributes(%{owner_type: "user", owner_id: user.id})
      assert {:ok, space} = Spaces.create_space(attrs)
      assert space.name == attrs.name
      assert space.slug == attrs.slug
      assert space.owner_type == "user"
      assert space.owner_id == user.id
    end

    test "returns error without owner" do
      assert {:error, changeset} = Spaces.create_space(%{name: "test", slug: "test"})
      assert errors_on(changeset) != %{}
    end
  end

  describe "list_public_spaces/1" do
    test "returns only public spaces" do
      user = user_fixture()
      _private = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})
      public = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})

      spaces = Spaces.list_public_spaces()
      assert length(spaces) == 1
      assert hd(spaces).id == public.id
    end
  end

  describe "list_user_spaces/2" do
    test "returns all spaces for the user" do
      user = user_fixture()
      _s1 = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      _s2 = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})

      spaces = Spaces.list_user_spaces(user.id)
      assert length(spaces) == 2
    end

    test "filters by visibility" do
      user = user_fixture()
      _s1 = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      _s2 = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})

      spaces = Spaces.list_user_spaces(user.id, visibility: "public")
      assert length(spaces) == 1
    end
  end

  describe "get_space_by_owner_and_slug/2" do
    test "returns space for valid owner and slug" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})
      assert found = Spaces.get_space_by_owner_and_slug(user.username, space.slug)
      assert found.id == space.id
    end

    test "returns nil for non-existent combo" do
      assert Spaces.get_space_by_owner_and_slug("nobody", "nothing") == nil
    end
  end

  describe "update_space/2" do
    test "updates fields" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})
      assert {:ok, updated} = Spaces.update_space(space, %{description: "new description"})
      assert updated.description == "new description"
    end
  end

  describe "delete_space/1" do
    test "deletes the space" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})
      assert {:ok, _} = Spaces.delete_space(space)

      assert_raise Ecto.NoResultsError, fn ->
        Spaces.get_space!(space.id)
      end
    end
  end

  describe "can_access?/2" do
    test "public space is accessible to nil user" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      assert Spaces.can_access?(space, nil) == true
    end

    test "private space is not accessible to nil user" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})
      assert Spaces.can_access?(space, nil) == false
    end

    test "private space is accessible to owner" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})
      assert Spaces.can_access?(space, user) == true
    end

    test "private org space is accessible to org member" do
      owner = user_fixture()
      member = user_fixture()
      org = organization_fixture(%{}, owner.id)

      # Add member to org
      {:ok, _} = Cyanea.Repo.insert(
        Cyanea.Organizations.Membership.changeset(%Cyanea.Organizations.Membership{}, %{
          user_id: member.id,
          organization_id: org.id,
          role: "member"
        })
      )

      space = space_fixture(%{owner_type: "organization", owner_id: org.id, visibility: "private"})
      assert Spaces.can_access?(space, member) == true
    end

    test "private space denies access to non-member" do
      user = user_fixture()
      other = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})
      assert Spaces.can_access?(space, other) == false
    end
  end

  describe "owner?/2" do
    test "returns true for owner" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})
      assert Spaces.owner?(space, user) == true
    end

    test "returns false for non-owner" do
      user = user_fixture()
      other = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})
      assert Spaces.owner?(space, other) == false
    end
  end

  describe "billing enforcement" do
    test "free user cannot create private space" do
      user = user_fixture()
      attrs = valid_space_attributes(%{owner_type: "user", owner_id: user.id, visibility: "private"})
      assert {:error, :pro_required} = Spaces.create_space(attrs)
    end

    test "pro user can create private space" do
      user = pro_user_fixture()
      attrs = valid_space_attributes(%{owner_type: "user", owner_id: user.id, visibility: "private"})
      assert {:ok, space} = Spaces.create_space(attrs)
      assert space.visibility == "private"
    end

    test "free user can create public space" do
      user = user_fixture()
      attrs = valid_space_attributes(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      assert {:ok, space} = Spaces.create_space(attrs)
      assert space.visibility == "public"
    end

    test "free user cannot change visibility to private" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      assert {:error, :pro_required} = Spaces.update_space(space, %{visibility: "private"})
    end

    test "pro user can change visibility to private" do
      user = pro_user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      assert {:ok, updated} = Spaces.update_space(space, %{visibility: "private"})
      assert updated.visibility == "private"
    end
  end

  describe "read_only?/1" do
    test "public space is never read-only" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      refute Spaces.read_only?(space)
    end

    test "private space with pro owner is not read-only" do
      user = pro_user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})
      refute Spaces.read_only?(space)
    end

    test "private space with free owner is read-only (downgrade scenario)" do
      user = user_fixture()
      # Create private space directly (bypassing billing check via fixture)
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})
      assert Spaces.read_only?(space)
    end
  end
end
