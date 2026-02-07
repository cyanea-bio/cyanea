defmodule Cyanea.FederationTest do
  use Cyanea.DataCase, async: true

  alias Cyanea.Federation
  alias Cyanea.Federation.Node

  import Cyanea.AccountsFixtures
  import Cyanea.RepositoriesFixtures
  import Cyanea.ArtifactsFixtures
  import Cyanea.FederationFixtures

  # ===========================================================================
  # Global IDs
  # ===========================================================================

  describe "parse_global_id/1" do
    test "parses a valid global ID with version" do
      assert {:ok, parsed} = Federation.parse_global_id("cyanea://hub.example.com/lab-x/rna-seq/counts@1.0.0")
      assert parsed.host == "hub.example.com"
      assert parsed.owner == "lab-x"
      assert parsed.repo == "rna-seq"
      assert parsed.slug == "counts"
      assert parsed.version == "1.0.0"
    end

    test "parses a global ID without version" do
      assert {:ok, parsed} = Federation.parse_global_id("cyanea://hub.example.com/lab/repo/artifact")
      assert parsed.slug == "artifact"
      assert parsed.version == nil
    end

    test "rejects invalid global IDs" do
      assert {:error, :invalid_global_id} = Federation.parse_global_id("https://example.com")
      assert {:error, :invalid_global_id} = Federation.parse_global_id("cyanea://host/only")
      assert {:error, :invalid_global_id} = Federation.parse_global_id("garbage")
    end
  end

  # ===========================================================================
  # Node Management
  # ===========================================================================

  describe "register_node/1" do
    test "creates a node in pending status" do
      attrs = %{name: "Test Node", url: "https://test.example.com"}
      assert {:ok, node} = Federation.register_node(attrs)
      assert node.name == "Test Node"
      assert node.url == "https://test.example.com"
      assert node.status == "pending"
    end

    test "fails with invalid URL" do
      assert {:error, changeset} = Federation.register_node(%{name: "Bad", url: "not-a-url"})
      assert errors_on(changeset)[:url]
    end

    test "enforces unique URL" do
      url = "https://unique-#{System.unique_integer([:positive])}.example.com"
      assert {:ok, _} = Federation.register_node(%{name: "First", url: url})
      assert {:error, changeset} = Federation.register_node(%{name: "Second", url: url})
      assert errors_on(changeset)[:url]
    end
  end

  describe "list_nodes/1" do
    test "returns all nodes" do
      _n1 = node_fixture()
      _n2 = node_fixture()
      assert length(Federation.list_nodes()) >= 2
    end

    test "filters by status" do
      node = node_fixture()
      {:ok, _} = Federation.activate_node(node)

      active = Federation.list_nodes(status: "active")
      pending = Federation.list_nodes(status: "pending")

      assert Enum.any?(active, &(&1.id == node.id))
      refute Enum.any?(pending, &(&1.id == node.id))
    end
  end

  describe "node lifecycle" do
    test "activate → deactivate → revoke" do
      node = node_fixture()
      assert node.status == "pending"

      {:ok, node} = Federation.activate_node(node)
      assert node.status == "active"

      {:ok, node} = Federation.deactivate_node(node)
      assert node.status == "inactive"

      {:ok, node} = Federation.revoke_node(node)
      assert node.status == "revoked"
    end

    test "touch_node_sync updates last_sync_at" do
      node = node_fixture()
      assert node.last_sync_at == nil

      {:ok, updated} = Federation.touch_node_sync(node)
      assert updated.last_sync_at != nil
    end
  end

  describe "get_node!/1" do
    test "returns node by ID" do
      node = node_fixture()
      assert Federation.get_node!(node.id).id == node.id
    end

    test "raises for non-existent ID" do
      assert_raise Ecto.NoResultsError, fn ->
        Federation.get_node!(Ecto.UUID.generate())
      end
    end
  end

  describe "get_node_by_url/1" do
    test "returns node by URL" do
      node = node_fixture()
      assert Federation.get_node_by_url(node.url).id == node.id
    end

    test "returns nil for unknown URL" do
      assert Federation.get_node_by_url("https://unknown.example.com") == nil
    end
  end

  # ===========================================================================
  # Manifests
  # ===========================================================================

  describe "publish_manifest/2" do
    setup do
      user = user_fixture()
      repo = repository_fixture(%{owner_id: user.id})
      artifact = artifact_fixture(%{repository_id: repo.id, author_id: user.id})
      %{user: user, repo: repo, artifact: artifact}
    end

    test "creates a manifest and assigns global ID", %{artifact: artifact} do
      assert {:ok, manifest} = Federation.publish_manifest(artifact)
      assert manifest.global_id != nil
      assert manifest.artifact_id == artifact.id
      assert manifest.content_hash != nil
    end

    test "manifest includes artifact metadata", %{artifact: artifact} do
      {:ok, manifest} = Federation.publish_manifest(artifact)
      assert manifest.payload["type"] == artifact.type
      assert manifest.payload["version"] == artifact.version
    end
  end

  describe "get_manifest_by_global_id/1" do
    setup do
      user = user_fixture()
      repo = repository_fixture(%{owner_id: user.id})
      artifact = artifact_fixture(%{repository_id: repo.id, author_id: user.id})
      {:ok, manifest} = Federation.publish_manifest(artifact)
      %{manifest: manifest}
    end

    test "returns manifest with preloads", %{manifest: manifest} do
      found = Federation.get_manifest_by_global_id(manifest.global_id)
      assert found.id == manifest.id
      assert found.artifact != nil
    end

    test "returns nil for unknown global ID" do
      assert Federation.get_manifest_by_global_id("cyanea://unknown/a/b/c@1.0.0") == nil
    end
  end

  # ===========================================================================
  # Sync
  # ===========================================================================

  describe "sync operations" do
    setup do
      node = node_fixture()
      %{node: node}
    end

    test "record, complete, and fail sync entries", %{node: node} do
      attrs = %{
        direction: "push",
        resource_type: "artifact",
        resource_id: Ecto.UUID.generate(),
        node_id: node.id
      }

      assert {:ok, entry} = Federation.record_sync(attrs)
      assert entry.status == "pending"
      assert entry.inserted_at != nil

      {:ok, completed} = Federation.complete_sync(entry)
      assert completed.status == "completed"
      assert completed.completed_at != nil
    end

    test "fail_sync records error message", %{node: node} do
      {:ok, entry} = Federation.record_sync(%{
        direction: "pull",
        resource_type: "manifest",
        resource_id: Ecto.UUID.generate(),
        node_id: node.id
      })

      {:ok, failed} = Federation.fail_sync(entry, "connection timeout")
      assert failed.status == "failed"
      assert failed.error_message == "connection timeout"
    end

    test "list_sync_entries returns entries for a node", %{node: node} do
      {:ok, _} = Federation.record_sync(%{
        direction: "push",
        resource_type: "artifact",
        resource_id: Ecto.UUID.generate(),
        node_id: node.id
      })

      entries = Federation.list_sync_entries(node.id)
      assert length(entries) == 1
    end

    test "pending_syncs returns only pending entries", %{node: node} do
      {:ok, entry} = Federation.record_sync(%{
        direction: "push",
        resource_type: "artifact",
        resource_id: Ecto.UUID.generate(),
        node_id: node.id
      })
      {:ok, _} = Federation.complete_sync(entry)

      {:ok, _} = Federation.record_sync(%{
        direction: "pull",
        resource_type: "manifest",
        resource_id: Ecto.UUID.generate(),
        node_id: node.id
      })

      pending = Federation.pending_syncs(node.id)
      assert length(pending) == 1
      assert hd(pending).direction == "pull"
    end
  end

  # ===========================================================================
  # Node changeset
  # ===========================================================================

  describe "Node changeset" do
    test "validates required fields" do
      changeset = Node.changeset(%Node{}, %{})
      assert errors_on(changeset)[:name]
      assert errors_on(changeset)[:url]
    end

    test "validates URL format" do
      changeset = Node.changeset(%Node{}, %{name: "test", url: "ftp://bad"})
      assert errors_on(changeset)[:url]
    end

    test "validates status inclusion" do
      changeset = Node.changeset(%Node{}, %{name: "test", url: "https://ok.com", status: "invalid"})
      assert errors_on(changeset)[:status]
    end
  end
end
