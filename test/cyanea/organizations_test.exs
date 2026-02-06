defmodule Cyanea.OrganizationsTest do
  use Cyanea.DataCase, async: true

  alias Cyanea.Organizations

  import Cyanea.AccountsFixtures
  import Cyanea.OrganizationsFixtures

  describe "create_organization/2" do
    test "creates organization and owner membership" do
      user = user_fixture()
      attrs = valid_org_attributes()
      assert {:ok, org} = Organizations.create_organization(attrs, user.id)
      assert org.name == attrs.name
      assert org.slug == attrs.slug

      membership = Organizations.get_membership(user.id, org.id)
      assert membership != nil
      assert membership.role == "owner"
    end

    test "returns error with invalid data" do
      user = user_fixture()
      assert {:error, changeset} = Organizations.create_organization(%{name: "", slug: ""}, user.id)
      assert errors_on(changeset) != %{}
    end

    test "returns error with duplicate slug" do
      user = user_fixture()
      attrs = valid_org_attributes()
      assert {:ok, _} = Organizations.create_organization(attrs, user.id)
      assert {:error, changeset} = Organizations.create_organization(%{attrs | name: "Other"}, user.id)
      assert "has already been taken" in errors_on(changeset).slug
    end
  end

  describe "list_user_organizations/1" do
    test "returns organizations the user belongs to" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)
      orgs = Organizations.list_user_organizations(user.id)
      assert length(orgs) == 1
      assert hd(orgs).id == org.id
    end

    test "returns empty list for user with no organizations" do
      user = user_fixture()
      assert Organizations.list_user_organizations(user.id) == []
    end
  end

  describe "get_organization_by_slug/1" do
    test "returns org for existing slug" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)
      assert found = Organizations.get_organization_by_slug(org.slug)
      assert found.id == org.id
    end

    test "returns nil for non-existent slug" do
      assert Organizations.get_organization_by_slug("nonexistent") == nil
    end
  end

  describe "get_membership/2" do
    test "returns membership for member" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)
      assert membership = Organizations.get_membership(user.id, org.id)
      assert membership.role == "owner"
    end

    test "returns nil for non-member" do
      user = user_fixture()
      other = user_fixture()
      org = organization_fixture(%{}, user.id)
      assert Organizations.get_membership(other.id, org.id) == nil
    end
  end

  describe "list_members/1" do
    test "returns members with user data" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)
      members = Organizations.list_members(org.id)
      assert length(members) == 1
      assert hd(members).user.id == user.id
    end
  end
end
