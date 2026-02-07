defmodule Cyanea.ArtifactsTest do
  use Cyanea.DataCase, async: true

  alias Cyanea.Artifacts
  alias Cyanea.Artifacts.Artifact

  import Cyanea.AccountsFixtures
  import Cyanea.RepositoriesFixtures
  import Cyanea.ArtifactsFixtures

  defp setup_repo(_context) do
    user = user_fixture()
    repo = repository_fixture(%{owner_id: user.id})
    %{user: user, repo: repo}
  end

  describe "create_artifact/1" do
    setup :setup_repo

    test "creates an artifact with valid attrs", %{user: user, repo: repo} do
      attrs = valid_artifact_attributes(%{repository_id: repo.id, author_id: user.id})
      assert {:ok, artifact} = Artifacts.create_artifact(attrs)
      assert artifact.name == attrs.name
      assert artifact.slug == attrs.slug
      assert artifact.type == "dataset"
      assert artifact.version == "1.0.0"
      assert artifact.repository_id == repo.id
      assert artifact.author_id == user.id
    end

    test "records a 'created' event", %{user: user, repo: repo} do
      attrs = valid_artifact_attributes(%{repository_id: repo.id, author_id: user.id})
      {:ok, artifact} = Artifacts.create_artifact(attrs)

      events = Artifacts.list_artifact_events(artifact.id)
      assert length(events) == 1
      assert hd(events).event_type == "created"
      assert hd(events).actor_id == user.id
    end

    test "fails without required fields" do
      assert {:error, changeset} = Artifacts.create_artifact(%{name: "test"})
      assert errors_on(changeset) != %{}
    end

    test "fails with invalid type", %{user: user, repo: repo} do
      attrs = valid_artifact_attributes(%{
        repository_id: repo.id,
        author_id: user.id,
        type: "invalid"
      })
      assert {:error, changeset} = Artifacts.create_artifact(attrs)
      assert errors_on(changeset)[:type]
    end

    test "fails with invalid version format", %{user: user, repo: repo} do
      attrs = valid_artifact_attributes(%{
        repository_id: repo.id,
        author_id: user.id,
        version: "bad"
      })
      assert {:error, changeset} = Artifacts.create_artifact(attrs)
      assert errors_on(changeset)[:version]
    end

    test "enforces unique slug per repository", %{user: user, repo: repo} do
      attrs = valid_artifact_attributes(%{
        repository_id: repo.id,
        author_id: user.id,
        slug: "unique-slug"
      })
      assert {:ok, _} = Artifacts.create_artifact(attrs)
      assert {:error, changeset} = Artifacts.create_artifact(attrs)
      assert errors_on(changeset)[:slug]
    end
  end

  describe "list_repository_artifacts/2" do
    setup :setup_repo

    test "returns artifacts for a repository", %{user: user, repo: repo} do
      _a1 = artifact_fixture(%{repository_id: repo.id, author_id: user.id})
      _a2 = artifact_fixture(%{repository_id: repo.id, author_id: user.id})

      artifacts = Artifacts.list_repository_artifacts(repo.id)
      assert length(artifacts) == 2
    end

    test "filters by type", %{user: user, repo: repo} do
      _dataset = artifact_fixture(%{repository_id: repo.id, author_id: user.id, type: "dataset"})
      _protocol = artifact_fixture(%{repository_id: repo.id, author_id: user.id, type: "protocol"})

      datasets = Artifacts.list_repository_artifacts(repo.id, type: "dataset")
      assert length(datasets) == 1
      assert hd(datasets).type == "dataset"
    end

    test "does not return artifacts from other repos", %{user: user, repo: repo} do
      other_repo = repository_fixture(%{owner_id: user.id})
      _a = artifact_fixture(%{repository_id: other_repo.id, author_id: user.id})

      assert Artifacts.list_repository_artifacts(repo.id) == []
    end
  end

  describe "get_artifact!/1" do
    setup :setup_repo

    test "returns the artifact with preloads", %{user: user, repo: repo} do
      artifact = artifact_fixture(%{repository_id: repo.id, author_id: user.id})
      found = Artifacts.get_artifact!(artifact.id)
      assert found.id == artifact.id
      assert found.author != nil
      assert found.repository != nil
    end

    test "raises for non-existent ID" do
      assert_raise Ecto.NoResultsError, fn ->
        Artifacts.get_artifact!(Ecto.UUID.generate())
      end
    end
  end

  describe "get_artifact_by_repo_and_slug/2" do
    setup :setup_repo

    test "returns artifact for valid repo and slug", %{user: user, repo: repo} do
      artifact = artifact_fixture(%{repository_id: repo.id, author_id: user.id})
      found = Artifacts.get_artifact_by_repo_and_slug(repo.id, artifact.slug)
      assert found.id == artifact.id
    end

    test "returns nil for non-existent slug", %{repo: repo} do
      assert Artifacts.get_artifact_by_repo_and_slug(repo.id, "nope") == nil
    end
  end

  describe "update_artifact/3" do
    setup :setup_repo

    test "updates fields and records event", %{user: user, repo: repo} do
      artifact = artifact_fixture(%{repository_id: repo.id, author_id: user.id})
      assert {:ok, updated} = Artifacts.update_artifact(artifact, %{description: "new desc"}, user.id)
      assert updated.description == "new desc"

      events = Artifacts.list_artifact_events(artifact.id)
      assert length(events) == 2
      assert List.last(events).event_type == "updated"
    end
  end

  describe "bump_version/3" do
    setup :setup_repo

    test "updates version and records event", %{user: user, repo: repo} do
      artifact = artifact_fixture(%{repository_id: repo.id, author_id: user.id})
      assert {:ok, bumped} = Artifacts.bump_version(artifact, "2.0.0", user.id)
      assert bumped.version == "2.0.0"

      events = Artifacts.list_artifact_events(artifact.id)
      version_event = Enum.find(events, &(&1.event_type == "version_bumped"))
      assert version_event.payload["from"] == "1.0.0"
      assert version_event.payload["to"] == "2.0.0"
    end
  end

  describe "derive_artifact/2" do
    setup :setup_repo

    test "creates derived artifact with lineage", %{user: user, repo: repo} do
      parent = artifact_fixture(%{repository_id: repo.id, author_id: user.id})

      attrs = valid_artifact_attributes(%{author_id: user.id})
      assert {:ok, derived} = Artifacts.derive_artifact(parent, attrs)
      assert derived.parent_artifact_id == parent.id
      assert derived.repository_id == repo.id

      # Check lineage
      lineage = Artifacts.lineage(derived)
      assert length(lineage) == 1
      assert hd(lineage).id == parent.id
    end

    test "records 'derived' event", %{user: user, repo: repo} do
      parent = artifact_fixture(%{repository_id: repo.id, author_id: user.id})
      attrs = valid_artifact_attributes(%{author_id: user.id})
      {:ok, derived} = Artifacts.derive_artifact(parent, attrs)

      events = Artifacts.list_artifact_events(derived.id)
      assert hd(events).event_type == "derived"
      assert hd(events).payload["parent_id"] == parent.id
    end
  end

  describe "list_derived_artifacts/1" do
    setup :setup_repo

    test "returns artifacts derived from a parent", %{user: user, repo: repo} do
      parent = artifact_fixture(%{repository_id: repo.id, author_id: user.id})
      attrs = valid_artifact_attributes(%{author_id: user.id})
      {:ok, _derived} = Artifacts.derive_artifact(parent, attrs)

      derived_list = Artifacts.list_derived_artifacts(parent.id)
      assert length(derived_list) == 1
    end
  end

  describe "lineage/1" do
    setup :setup_repo

    test "returns empty for root artifact", %{user: user, repo: repo} do
      root = artifact_fixture(%{repository_id: repo.id, author_id: user.id})
      assert Artifacts.lineage(root) == []
    end

    test "walks full ancestor chain", %{user: user, repo: repo} do
      grandparent = artifact_fixture(%{repository_id: repo.id, author_id: user.id})

      {:ok, parent} =
        Artifacts.derive_artifact(grandparent, valid_artifact_attributes(%{author_id: user.id}))

      {:ok, child} =
        Artifacts.derive_artifact(parent, valid_artifact_attributes(%{author_id: user.id}))

      lineage = Artifacts.lineage(child)
      assert length(lineage) == 2
      assert hd(lineage).id == parent.id
      assert List.last(lineage).id == grandparent.id
    end
  end

  describe "delete_artifact/1" do
    setup :setup_repo

    test "deletes the artifact", %{user: user, repo: repo} do
      artifact = artifact_fixture(%{repository_id: repo.id, author_id: user.id})
      assert {:ok, _} = Artifacts.delete_artifact(artifact)

      assert_raise Ecto.NoResultsError, fn ->
        Artifacts.get_artifact!(artifact.id)
      end
    end
  end

  describe "can_access?/2" do
    setup :setup_repo

    test "public artifact is accessible to nil user", %{user: user, repo: repo} do
      artifact = artifact_fixture(%{repository_id: repo.id, author_id: user.id, visibility: "public"})
      assert Artifacts.can_access?(artifact, nil) == true
    end

    test "private artifact is not accessible to nil user", %{user: user, repo: repo} do
      artifact = artifact_fixture(%{repository_id: repo.id, author_id: user.id, visibility: "private"})
      assert Artifacts.can_access?(artifact, nil) == false
    end

    test "private artifact is accessible to author", %{user: user, repo: repo} do
      artifact = artifact_fixture(%{repository_id: repo.id, author_id: user.id, visibility: "private"})
      assert Artifacts.can_access?(artifact, user) == true
    end
  end

  describe "list_public_artifacts/1" do
    setup :setup_repo

    test "returns only public artifacts", %{user: user, repo: repo} do
      _public = artifact_fixture(%{repository_id: repo.id, author_id: user.id, visibility: "public"})
      _private = artifact_fixture(%{repository_id: repo.id, author_id: user.id, visibility: "private"})

      artifacts = Artifacts.list_public_artifacts()
      assert length(artifacts) == 1
      assert hd(artifacts).visibility == "public"
    end
  end

  describe "Artifact changeset" do
    test "validates slug format" do
      changeset = Artifact.changeset(%Artifact{}, %{slug: "INVALID SLUG!"})
      assert errors_on(changeset)[:slug]
    end

    test "accepts valid slug" do
      changeset = Artifact.changeset(%Artifact{}, %{
        slug: "my-dataset.v2",
        name: "test",
        type: "dataset",
        repository_id: Ecto.UUID.generate(),
        author_id: Ecto.UUID.generate()
      })
      refute errors_on(changeset)[:slug]
    end
  end
end
