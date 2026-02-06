defmodule Cyanea.RepositoriesTest do
  use Cyanea.DataCase, async: true

  alias Cyanea.Repositories

  import Cyanea.AccountsFixtures
  import Cyanea.OrganizationsFixtures
  import Cyanea.RepositoriesFixtures

  describe "create_repository/1" do
    test "creates a user-owned repository" do
      user = user_fixture()
      attrs = valid_repo_attributes(%{owner_id: user.id})
      assert {:ok, repo} = Repositories.create_repository(attrs)
      assert repo.name == attrs.name
      assert repo.slug == attrs.slug
      assert repo.owner_id == user.id
    end

    test "returns error without owner or org" do
      assert {:error, changeset} = Repositories.create_repository(%{name: "test", slug: "test"})
      assert errors_on(changeset) != %{}
    end
  end

  describe "list_public_repositories/1" do
    test "returns only public repositories" do
      user = user_fixture()
      _private = repository_fixture(%{owner_id: user.id, visibility: "private"})
      public = repository_fixture(%{owner_id: user.id, visibility: "public"})

      repos = Repositories.list_public_repositories()
      assert length(repos) == 1
      assert hd(repos).id == public.id
    end
  end

  describe "list_user_repositories/2" do
    test "returns all repos for the user" do
      user = user_fixture()
      _r1 = repository_fixture(%{owner_id: user.id, visibility: "public"})
      _r2 = repository_fixture(%{owner_id: user.id, visibility: "private"})

      repos = Repositories.list_user_repositories(user.id)
      assert length(repos) == 2
    end

    test "filters by visibility" do
      user = user_fixture()
      _r1 = repository_fixture(%{owner_id: user.id, visibility: "public"})
      _r2 = repository_fixture(%{owner_id: user.id, visibility: "private"})

      repos = Repositories.list_user_repositories(user.id, visibility: "public")
      assert length(repos) == 1
    end
  end

  describe "get_repository_by_owner_and_slug/2" do
    test "returns repo for valid owner and slug" do
      user = user_fixture()
      repo = repository_fixture(%{owner_id: user.id})
      assert found = Repositories.get_repository_by_owner_and_slug(user.username, repo.slug)
      assert found.id == repo.id
    end

    test "returns nil for non-existent combo" do
      assert Repositories.get_repository_by_owner_and_slug("nobody", "nothing") == nil
    end
  end

  describe "can_access?/2" do
    test "public repo is accessible to nil user" do
      user = user_fixture()
      repo = repository_fixture(%{owner_id: user.id, visibility: "public"})
      assert Repositories.can_access?(repo, nil) == true
    end

    test "private repo is not accessible to nil user" do
      user = user_fixture()
      repo = repository_fixture(%{owner_id: user.id, visibility: "private"})
      assert Repositories.can_access?(repo, nil) == false
    end

    test "private repo is accessible to owner" do
      user = user_fixture()
      repo = repository_fixture(%{owner_id: user.id, visibility: "private"})
      assert Repositories.can_access?(repo, user) == true
    end

    test "private org repo is accessible to org member" do
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

      repo = repository_fixture(%{organization_id: org.id, visibility: "private"})
      assert Repositories.can_access?(repo, member) == true
    end

    test "private repo denies access to non-member" do
      user = user_fixture()
      other = user_fixture()
      repo = repository_fixture(%{owner_id: user.id, visibility: "private"})
      assert Repositories.can_access?(repo, other) == false
    end
  end
end
