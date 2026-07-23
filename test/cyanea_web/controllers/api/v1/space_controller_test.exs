defmodule CyaneaWeb.Api.V1.SpaceControllerTest do
  use CyaneaWeb.ConnCase

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  setup do
    user = user_fixture()
    space = space_fixture(owner_type: "user", owner_id: user.id, visibility: "public")
    %{user: user, space: space}
  end

  describe "GET /api/v1/spaces" do
    test "lists public spaces", %{conn: conn, space: space} do
      conn = get(conn, "/api/v1/spaces")
      assert %{"data" => spaces} = json_response(conn, 200)
      assert Enum.any?(spaces, &(&1["id"] == space.id))
    end

    test "does not include private spaces", %{conn: conn, user: user} do
      _private = space_fixture(owner_type: "user", owner_id: user.id, visibility: "private")
      conn = get(conn, "/api/v1/spaces")
      assert %{"data" => spaces} = json_response(conn, 200)
      assert Enum.all?(spaces, &(&1["visibility"] == "public"))
    end
  end

  describe "GET /api/v1/spaces/:id" do
    test "returns a public space", %{conn: conn, space: space} do
      conn = get(conn, "/api/v1/spaces/#{space.id}")
      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == space.id
      assert data["name"] == space.name
    end

    test "returns 404 for private space without auth", %{conn: conn, user: user} do
      private = space_fixture(owner_type: "user", owner_id: user.id, visibility: "private")
      conn = get(conn, "/api/v1/spaces/#{private.id}")
      assert json_response(conn, 404)
    end

    test "returns private space to owner", %{conn: conn, user: user} do
      private = space_fixture(owner_type: "user", owner_id: user.id, visibility: "private")

      conn =
        conn
        |> api_auth_conn(user)
        |> get("/api/v1/spaces/#{private.id}")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == private.id
    end

    test "returns 404 for nonexistent space", %{conn: conn} do
      conn = get(conn, "/api/v1/spaces/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end
  end

  describe "GET /api/v1/:owner/:slug" do
    test "returns space by owner and slug", %{conn: conn, user: user, space: space} do
      conn = get(conn, "/api/v1/#{user.username}/#{space.slug}")
      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == space.id
    end

    test "returns 404 for nonexistent slug", %{conn: conn, user: user} do
      conn = get(conn, "/api/v1/#{user.username}/nonexistent")
      assert json_response(conn, 404)
    end
  end

  describe "POST /api/v1/spaces" do
    test "creates a space when authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/spaces", %{
          name: "New Space",
          slug: "new-space",
          description: "A new space"
        })

      assert %{"data" => data} = json_response(conn, 201)
      assert data["name"] == "New Space"
      assert data["slug"] == "new-space"
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/spaces", %{name: "Test"})

      assert json_response(conn, 401)
    end

    test "returns 403 for read-only token", %{conn: conn, user: user} do
      conn =
        conn
        |> api_auth_conn(user, scopes: ["read"])
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/spaces", %{name: "Test", slug: "test"})

      assert json_response(conn, 403)
    end

    test "returns 422 for invalid data", %{conn: conn, user: user} do
      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/spaces", %{name: ""})

      assert json_response(conn, 422)
    end
  end

  describe "PATCH /api/v1/spaces/:id" do
    test "updates a space", %{conn: conn, user: user, space: space} do
      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> patch("/api/v1/spaces/#{space.id}", %{description: "Updated"})

      assert %{"data" => data} = json_response(conn, 200)
      assert data["description"] == "Updated"
    end

    test "updates and returns the readme", %{conn: conn, user: user, space: space} do
      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> patch("/api/v1/spaces/#{space.id}", %{readme: "# Overview\n\nHello."})

      assert %{"data" => data} = json_response(conn, 200)
      assert data["readme"] == "# Overview\n\nHello."
    end

    test "returns 403 for non-owner", %{conn: conn, space: space} do
      other_user = user_fixture()

      conn =
        conn
        |> api_auth_conn(other_user)
        |> put_req_header("content-type", "application/json")
        |> patch("/api/v1/spaces/#{space.id}", %{description: "Hacked"})

      assert json_response(conn, 403)
    end
  end

  describe "DELETE /api/v1/spaces/:id" do
    test "deletes a space", %{conn: conn, user: user, space: space} do
      conn =
        conn
        |> api_auth_conn(user)
        |> delete("/api/v1/spaces/#{space.id}")

      assert %{"data" => %{"message" => "Space deleted"}} = json_response(conn, 200)
    end
  end

  describe "POST /api/v1/spaces/:id/fork" do
    test "forks a space", %{conn: conn, space: space} do
      other_user = user_fixture()

      conn =
        conn
        |> api_auth_conn(other_user)
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/spaces/#{space.id}/fork", %{name: "My Fork", slug: "my-fork"})

      assert %{"data" => data} = json_response(conn, 201)
      assert data["name"] == "My Fork"
      assert data["forked_from_id"] == space.id
    end
  end
end
