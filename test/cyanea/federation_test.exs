defmodule Cyanea.FederationTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Federation
  alias Cyanea.Federation.Node

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.FederationFixtures

  # ===========================================================================
  # Global IDs
  # ===========================================================================

  describe "parse_global_id/1" do
    test "parses a valid global ID" do
      assert {:ok, parsed} = Federation.parse_global_id("cyanea://hub.example.com/lab-x/rna-seq")
      assert parsed.host == "hub.example.com"
      assert parsed.owner == "lab-x"
      assert parsed.slug == "rna-seq"
    end

    test "rejects invalid global IDs" do
      assert {:error, :invalid_global_id} = Federation.parse_global_id("https://example.com")
      assert {:error, :invalid_global_id} = Federation.parse_global_id("cyanea://host/only")
      assert {:error, :invalid_global_id} = Federation.parse_global_id("garbage")
    end
  end

  describe "local_global_id?/1" do
    test "detects non-local global IDs" do
      refute Federation.local_global_id?("cyanea://other-host.com/owner/slug")
    end

    test "rejects invalid global IDs" do
      refute Federation.local_global_id?("garbage")
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

  describe "get_node/1" do
    test "returns node by ID" do
      node = node_fixture()
      assert Federation.get_node(node.id).id == node.id
    end

    test "returns nil for non-existent ID" do
      assert Federation.get_node(Ecto.UUID.generate()) == nil
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

  describe "node_sync_stats/1" do
    test "returns zero stats for node with no syncs" do
      node = node_fixture()
      stats = Federation.node_sync_stats(node.id)
      assert stats.total == 0
      assert stats.completed == 0
      assert stats.failed == 0
    end

    test "returns correct stats after sync operations" do
      node = node_fixture()

      {:ok, entry1} = Federation.record_sync(%{
        direction: "push", resource_type: "space",
        resource_id: Ecto.UUID.generate(), node_id: node.id
      })
      Federation.complete_sync(entry1, bytes_transferred: 1024)

      {:ok, entry2} = Federation.record_sync(%{
        direction: "push", resource_type: "space",
        resource_id: Ecto.UUID.generate(), node_id: node.id
      })
      Federation.fail_sync(entry2, "timeout")

      stats = Federation.node_sync_stats(node.id)
      assert stats.total == 2
      assert stats.completed == 1
    end
  end

  # ===========================================================================
  # Manifests
  # ===========================================================================

  describe "publish_manifest/2" do
    setup do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})
      %{user: user, space: space}
    end

    test "creates a manifest and assigns global ID", %{space: space} do
      assert {:ok, manifest} = Federation.publish_manifest(space)
      assert manifest.global_id != nil
      assert manifest.space_id == space.id
      assert manifest.content_hash != nil
    end

    test "manifest includes comprehensive payload", %{space: space} do
      {:ok, manifest} = Federation.publish_manifest(space)
      assert manifest.payload["name"] == space.name
      assert manifest.payload["visibility"] == space.visibility
      assert manifest.payload["owner_type"] == space.owner_type
      assert is_list(manifest.payload["tags"])
    end

    test "manifest tracks revision number", %{space: space} do
      {:ok, manifest} = Federation.publish_manifest(space)
      # No revision created yet
      assert manifest.revision_number == nil
    end
  end

  describe "get_manifest_by_global_id/1" do
    setup do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})
      {:ok, manifest} = Federation.publish_manifest(space)
      %{manifest: manifest}
    end

    test "returns manifest with preloads", %{manifest: manifest} do
      found = Federation.get_manifest_by_global_id(manifest.global_id)
      assert found.id == manifest.id
      assert found.space != nil
    end

    test "returns nil for unknown global ID" do
      assert Federation.get_manifest_by_global_id("cyanea://unknown/a/b") == nil
    end
  end

  describe "list_manifests/1" do
    test "filters by status" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})
      {:ok, _manifest} = Federation.publish_manifest(space)

      published = Federation.list_manifests(status: "published")
      assert length(published) >= 1

      retracted = Federation.list_manifests(status: "retracted")
      refute Enum.any?(retracted, &(&1.space_id == space.id))
    end
  end

  # ===========================================================================
  # Publishing Workflow
  # ===========================================================================

  describe "publish_space/2" do
    setup do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      %{user: user, space: space}
    end

    test "publishes a space and creates manifest", %{space: space} do
      assert {:ok, manifest} = Federation.publish_space(space)
      assert manifest.global_id != nil
      assert manifest.status == "published"
    end

    test "sets federation_policy to full", %{space: space} do
      assert space.federation_policy == "none"
      {:ok, _manifest} = Federation.publish_space(space)

      updated = Cyanea.Repo.get!(Cyanea.Spaces.Space, space.id)
      assert updated.federation_policy == "full"
    end

    test "enqueues sync entries for active nodes", %{space: space} do
      node = node_fixture()
      {:ok, _} = Federation.activate_node(node)

      {:ok, _manifest} = Federation.publish_space(space)

      pending = Federation.pending_syncs(node.id)
      assert length(pending) >= 1
      assert hd(pending).resource_type == "space"
      assert hd(pending).direction == "push"
    end

    test "republish updates existing manifest", %{space: space} do
      {:ok, manifest1} = Federation.publish_space(space)
      {:ok, manifest2} = Federation.publish_space(space)

      # Should update, not create new
      assert manifest2.id == manifest1.id
    end
  end

  describe "unpublish_space/2" do
    setup do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      {:ok, _} = Federation.publish_space(space)
      space = Cyanea.Repo.get!(Cyanea.Spaces.Space, space.id)
      %{space: space}
    end

    test "retracts the manifest", %{space: space} do
      {:ok, updated_space} = Federation.unpublish_space(space)
      assert updated_space.federation_policy == "none"

      manifest = Federation.get_active_manifest(space.id)
      assert manifest == nil
    end

    test "retraction includes reason", %{space: space} do
      {:ok, _} = Federation.unpublish_space(space, "no longer relevant")

      # Check the manifest directly
      manifest =
        Cyanea.Repo.get_by(Cyanea.Federation.Manifest, space_id: space.id)

      assert manifest.status == "retracted"
      assert manifest.retracted_reason == "no longer relevant"
    end
  end

  describe "update_federation_policy/2" do
    test "updates the policy" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})
      assert space.federation_policy == "none"

      {:ok, updated} = Federation.update_federation_policy(space, "selective")
      assert updated.federation_policy == "selective"

      {:ok, updated} = Federation.update_federation_policy(updated, "full")
      assert updated.federation_policy == "full"
    end
  end

  describe "list_published_spaces/0" do
    test "returns spaces with active manifests" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      {:ok, _} = Federation.publish_space(space)

      published = Federation.list_published_spaces()
      assert Enum.any?(published, fn {s, _m} -> s.id == space.id end)
    end

    test "excludes retracted spaces" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      {:ok, _} = Federation.publish_space(space)

      space = Cyanea.Repo.get!(Cyanea.Spaces.Space, space.id)
      {:ok, _} = Federation.unpublish_space(space)

      published = Federation.list_published_spaces()
      refute Enum.any?(published, fn {s, _m} -> s.id == space.id end)
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
        resource_type: "space",
        resource_id: Ecto.UUID.generate(),
        node_id: node.id
      }

      assert {:ok, entry} = Federation.record_sync(attrs)
      assert entry.status == "pending"
      assert entry.inserted_at != nil

      {:ok, completed} = Federation.complete_sync(entry, bytes_transferred: 512)
      assert completed.status == "completed"
      assert completed.completed_at != nil
      assert completed.bytes_transferred == 512
    end

    test "fail_sync records error message", %{node: node} do
      {:ok, entry} = Federation.record_sync(%{
        direction: "pull",
        resource_type: "manifest",
        resource_id: Ecto.UUID.generate(),
        node_id: node.id
      })

      {:ok, failed} = Federation.fail_sync(entry, "connection timeout")
      # With retries remaining, it should be set back to pending with next_retry_at
      assert failed.status == "pending"
      assert failed.retries == 1
      assert failed.next_retry_at != nil
    end

    test "fail_sync marks as failed after max retries", %{node: node} do
      {:ok, entry} = Federation.record_sync(%{
        direction: "pull",
        resource_type: "manifest",
        resource_id: Ecto.UUID.generate(),
        node_id: node.id
      })

      # Set retries to max
      {:ok, entry} = entry
        |> Cyanea.Federation.SyncEntry.changeset(%{retries: 5, max_retries: 5})
        |> Cyanea.Repo.update()

      {:ok, failed} = Federation.fail_sync(entry, "permanent failure")
      assert failed.status == "failed"
      assert failed.error_message == "permanent failure"
    end

    test "list_sync_entries returns entries for a node", %{node: node} do
      {:ok, _} = Federation.record_sync(%{
        direction: "push",
        resource_type: "space",
        resource_id: Ecto.UUID.generate(),
        node_id: node.id
      })

      entries = Federation.list_sync_entries(node.id)
      assert length(entries) == 1
    end

    test "pending_syncs returns only pending entries", %{node: node} do
      {:ok, entry} = Federation.record_sync(%{
        direction: "push",
        resource_type: "space",
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

  describe "retryable_syncs/0" do
    test "returns entries with next_retry_at in the past" do
      node = node_fixture()
      past = DateTime.utc_now() |> DateTime.add(-60, :second) |> DateTime.truncate(:second)

      {:ok, entry} = Federation.record_sync(%{
        direction: "push",
        resource_type: "space",
        resource_id: Ecto.UUID.generate(),
        node_id: node.id
      })

      {:ok, _} = entry
        |> Cyanea.Federation.SyncEntry.changeset(%{next_retry_at: past})
        |> Cyanea.Repo.update()

      retryable = Federation.retryable_syncs()
      assert length(retryable) >= 1
    end
  end

  # ===========================================================================
  # Revision Sync
  # ===========================================================================

  describe "revisions_since/2" do
    test "returns revisions after a given number" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})

      {:ok, _rev1} = Cyanea.Revisions.create_revision(%{
        space_id: space.id, author_id: user.id, summary: "First"
      })
      {:ok, _rev2} = Cyanea.Revisions.create_revision(%{
        space_id: space.id, author_id: user.id, summary: "Second"
      })

      revisions = Federation.revisions_since(space.id, 0)
      assert length(revisions) == 2

      revisions = Federation.revisions_since(space.id, 1)
      assert length(revisions) == 1
      assert hd(revisions).number == 2
    end
  end

  describe "space_blob_ids/1" do
    test "returns empty list for space with no files" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})
      assert Federation.space_blob_ids(space.id) == []
    end
  end

  # ===========================================================================
  # Discovery
  # ===========================================================================

  describe "search_manifests/2" do
    test "searches by name in payload" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      {:ok, _} = Federation.publish_manifest(space)

      results = Federation.search_manifests(space.name)
      assert length(results) >= 1
    end

    test "returns empty for non-matching query" do
      results = Federation.search_manifests("nonexistent-space-xyz-123")
      assert results == []
    end
  end

  describe "receive_remote_manifest/1" do
    test "stores a remote manifest" do
      node = node_fixture()
      global_id = "cyanea://remote.example.com/user/test-space-#{System.unique_integer([:positive])}"

      attrs = %{
        global_id: global_id,
        content_hash: "abc123",
        payload: %{"name" => "Remote Space"},
        node_id: node.id,
        space_id: nil
      }

      assert {:ok, manifest} = Federation.receive_remote_manifest(attrs)
      assert manifest.global_id == global_id
      assert manifest.payload["name"] == "Remote Space"
    end

    test "upserts on conflict" do
      node = node_fixture()
      global_id = "cyanea://remote.example.com/user/upsert-test-#{System.unique_integer([:positive])}"

      attrs = %{
        global_id: global_id,
        content_hash: "abc123",
        payload: %{"name" => "Version 1"},
        node_id: node.id,
        space_id: nil
      }

      {:ok, m1} = Federation.receive_remote_manifest(attrs)

      attrs2 = %{attrs | content_hash: "def456", payload: %{"name" => "Version 2"}}
      {:ok, m2} = Federation.receive_remote_manifest(attrs2)

      assert m2.id == m1.id
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
