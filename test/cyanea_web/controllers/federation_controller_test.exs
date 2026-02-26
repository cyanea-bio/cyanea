defmodule CyaneaWeb.FederationControllerTest do
  use CyaneaWeb.ConnCase, async: false

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.FederationFixtures

  alias Cyanea.Federation

  describe "GET /api/federation/health" do
    test "returns health status", %{conn: conn} do
      conn = get(conn, "/api/federation/health")
      response = json_response(conn, 200)

      assert response["status"] == "ok"
      assert response["version"] == "0.5.0"
      assert response["timestamp"]
    end
  end

  describe "GET /api/federation/manifests" do
    test "returns published manifests", %{conn: conn} do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      {:ok, _} = Federation.publish_manifest(space)

      conn = get(conn, "/api/federation/manifests")
      response = json_response(conn, 200)

      assert is_list(response["manifests"])
      assert length(response["manifests"]) >= 1
    end
  end

  describe "GET /api/federation/manifests/:global_id" do
    test "returns a specific manifest", %{conn: conn} do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
      {:ok, manifest} = Federation.publish_manifest(space)

      encoded_id = URI.encode(manifest.global_id, &URI.char_unreserved?/1)
      conn = get(conn, "/api/federation/manifests/#{encoded_id}")
      response = json_response(conn, 200)

      assert response["manifest"]["global_id"] == manifest.global_id
    end

    test "returns 404 for unknown manifest", %{conn: conn} do
      encoded = URI.encode("cyanea://unknown/a/b", &URI.char_unreserved?/1)
      conn = get(conn, "/api/federation/manifests/#{encoded}")
      assert json_response(conn, 404)["error"] == "Manifest not found"
    end
  end

  describe "POST /api/federation/sync/push" do
    test "accepts a manifest push", %{conn: conn} do
      global_id = "cyanea://remote.example.com/lab/test-#{System.unique_integer([:positive])}"

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/federation/sync/push", %{
          node_url: "https://remote-#{System.unique_integer([:positive])}.example.com",
          manifest: %{
            global_id: global_id,
            content_hash: "abc123",
            payload: %{name: "Remote Space"},
            revision_number: 1,
            space_id: nil
          }
        })

      assert json_response(conn, 201)["status"] == "accepted"
    end

    test "returns 400 for missing fields", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/federation/sync/push", %{})

      assert json_response(conn, 400)["error"]
    end
  end

  describe "POST /api/federation/register" do
    test "registers a new remote node", %{conn: conn} do
      url = "https://new-node-#{System.unique_integer([:positive])}.example.com"

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/federation/register", %{
          name: "New Node",
          url: url
        })

      response = json_response(conn, 201)
      assert response["status"] == "registered"
      assert response["node_id"]
      assert response["node_status"] == "pending"
    end

    test "returns existing for already registered node", %{conn: conn} do
      node = node_fixture()

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/federation/register", %{
          name: node.name,
          url: node.url
        })

      response = json_response(conn, 200)
      assert response["status"] == "already_registered"
      assert response["node_id"] == node.id
    end

    test "returns 400 for missing fields", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/federation/register", %{})

      assert json_response(conn, 400)["error"]
    end
  end

  describe "GET /api/federation/revisions/:space_id" do
    test "returns revisions for a space", %{conn: conn} do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})

      {:ok, _} = Cyanea.Revisions.create_revision(%{
        space_id: space.id, author_id: user.id, summary: "Initial"
      })

      conn = get(conn, "/api/federation/revisions/#{space.id}")
      response = json_response(conn, 200)

      assert response["space_id"] == space.id
      assert length(response["revisions"]) == 1
    end

    test "supports since parameter", %{conn: conn} do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})

      {:ok, _} = Cyanea.Revisions.create_revision(%{
        space_id: space.id, author_id: user.id, summary: "First"
      })
      {:ok, _} = Cyanea.Revisions.create_revision(%{
        space_id: space.id, author_id: user.id, summary: "Second"
      })

      conn = get(conn, "/api/federation/revisions/#{space.id}?since=1")
      response = json_response(conn, 200)

      assert length(response["revisions"]) == 1
    end
  end

  describe "GET /api/federation/blobs/:space_id" do
    test "returns blob hashes for a space", %{conn: conn} do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})

      conn = get(conn, "/api/federation/blobs/#{space.id}")
      response = json_response(conn, 200)

      assert response["space_id"] == space.id
      assert response["blobs"] == []
    end
  end
end
