defmodule CyaneaWeb.Api.V1.LearnControllerTest do
  use CyaneaWeb.ConnCase

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.LearnFixtures

  alias Cyanea.Learn

  setup do
    user = user_fixture()
    %{user: user}
  end

  describe "GET /api/v1/learn/tracks" do
    test "returns published tracks", %{conn: conn} do
      track = track_fixture(%{published: true})
      _unpublished = track_fixture(%{published: false})

      conn = get(conn, "/api/v1/learn/tracks")
      assert %{"data" => tracks} = json_response(conn, 200)
      assert length(tracks) == 1
      assert hd(tracks)["id"] == track.id
      assert hd(tracks)["title"] == track.title
    end

    test "does not require authentication", %{conn: conn} do
      conn = get(conn, "/api/v1/learn/tracks")
      assert json_response(conn, 200)
    end
  end

  describe "GET /api/v1/learn/tracks/:slug" do
    test "returns track with paths", %{conn: conn} do
      track = track_fixture(%{published: true})
      _path = path_fixture(%{track_id: track.id, position: 0})

      conn = get(conn, "/api/v1/learn/tracks/#{track.slug}")
      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == track.id
      assert is_list(data["paths"])
      assert length(data["paths"]) == 1
    end

    test "returns 404 for unknown slug", %{conn: conn} do
      conn = get(conn, "/api/v1/learn/tracks/nonexistent")
      assert json_response(conn, 404)
    end
  end

  describe "GET /api/v1/learn/paths/:id" do
    test "returns path with units", %{conn: conn, user: user} do
      track = track_fixture()
      path = path_fixture(%{track_id: track.id})
      space = space_fixture(%{owner_type: "user", owner_id: user.id, space_type: "learn"})
      Learn.add_unit_to_path(%{path_id: path.id, space_id: space.id, position: 0, estimated_minutes: 15})

      conn = get(conn, "/api/v1/learn/paths/#{path.id}")
      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == path.id
      assert is_list(data["units"])
      assert length(data["units"]) == 1

      unit = hd(data["units"])
      assert unit["estimated_minutes"] == 15
      assert unit["space"]["id"] == space.id
    end

    test "returns 404 for unknown path", %{conn: conn} do
      conn = get(conn, "/api/v1/learn/paths/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end
  end

  describe "POST /api/v1/learn/units/:space_id/fork" do
    test "creates fork + progress when authenticated", %{conn: conn, user: user} do
      owner = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: owner.id, space_type: "learn"})

      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/learn/units/#{space.id}/fork", %{checkpoints_total: 3})

      assert %{"data" => data} = json_response(conn, 201)
      assert data["fork"]["forked_from_id"] == space.id
      assert data["progress"]["space_id"] == space.id
      assert data["progress"]["checkpoints_total"] == 3
      assert data["progress"]["status"] == "in_progress"
    end

    test "returns 401 without auth", %{conn: conn, user: user} do
      space = space_fixture(%{owner_type: "user", owner_id: user.id, space_type: "learn"})

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/learn/units/#{space.id}/fork")

      assert json_response(conn, 401)
    end

    test "returns 400 for non-learn space", %{conn: conn, user: user} do
      space = space_fixture(%{owner_type: "user", owner_id: user.id, space_type: "default"})

      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/learn/units/#{space.id}/fork")

      assert json_response(conn, 400)
    end
  end

  describe "GET /api/v1/learn/progress" do
    test "returns user's progress records", %{conn: conn, user: user} do
      space = space_fixture(%{owner_type: "user", owner_id: user.id, space_type: "learn"})
      {:ok, _} = Learn.get_or_create_progress(user.id, space.id)

      conn =
        conn
        |> api_auth_conn(user)
        |> get("/api/v1/learn/progress")

      assert %{"data" => progress_list} = json_response(conn, 200)
      assert length(progress_list) == 1
      assert hd(progress_list)["space_id"] == space.id
    end

    test "returns 401 without auth", %{conn: conn} do
      conn = get(conn, "/api/v1/learn/progress")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/v1/learn/progress/completed" do
    test "returns list of completed slugs", %{conn: conn, user: user} do
      space = space_fixture(%{owner_type: "user", owner_id: user.id, space_type: "learn"})
      {:ok, progress} = Learn.get_or_create_progress(user.id, space.id)
      {:ok, _} = Learn.mark_completed(progress)

      conn =
        conn
        |> api_auth_conn(user)
        |> get("/api/v1/learn/progress/completed")

      assert %{"data" => slugs} = json_response(conn, 200)
      assert is_list(slugs)
      assert space.slug in slugs
    end

    test "returns empty list for no completed units", %{conn: conn, user: user} do
      conn =
        conn
        |> api_auth_conn(user)
        |> get("/api/v1/learn/progress/completed")

      assert %{"data" => []} = json_response(conn, 200)
    end
  end

  describe "PATCH /api/v1/learn/progress/:id/checkpoint" do
    test "increments checkpoint count", %{conn: conn, user: user} do
      space = space_fixture(%{owner_type: "user", owner_id: user.id, space_type: "learn"})
      {:ok, progress} = Learn.get_or_create_progress(user.id, space.id)

      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> patch("/api/v1/learn/progress/#{progress.id}/checkpoint")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["checkpoints_passed"] == 1
      assert data["status"] == "in_progress"
    end

    test "returns 404 for nonexistent progress", %{conn: conn, user: user} do
      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> patch("/api/v1/learn/progress/#{Ecto.UUID.generate()}/checkpoint")

      assert json_response(conn, 404)
    end

    test "returns 403 for another user's progress", %{conn: conn, user: user} do
      other_user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, space_type: "learn"})
      {:ok, progress} = Learn.get_or_create_progress(other_user.id, space.id)

      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> patch("/api/v1/learn/progress/#{progress.id}/checkpoint")

      assert json_response(conn, 403)
    end
  end
end
