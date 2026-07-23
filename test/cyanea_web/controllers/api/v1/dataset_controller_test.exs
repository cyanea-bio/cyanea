defmodule CyaneaWeb.Api.V1.DatasetControllerTest do
  use CyaneaWeb.ConnCase

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  setup do
    user = user_fixture()
    space = space_fixture(owner_type: "user", owner_id: user.id, visibility: "public")

    {:ok, dataset} =
      Cyanea.Datasets.create_dataset(%{
        space_id: space.id,
        name: "Test Dataset",
        slug: "test-dataset",
        description: "A test dataset"
      })

    %{user: user, space: space, dataset: dataset}
  end

  describe "GET /api/v1/spaces/:space_id/datasets" do
    test "lists datasets", %{conn: conn, space: space, dataset: dataset} do
      conn = get(conn, "/api/v1/spaces/#{space.id}/datasets")
      assert %{"data" => datasets} = json_response(conn, 200)
      assert Enum.any?(datasets, &(&1["id"] == dataset.id))
    end
  end

  describe "GET /api/v1/spaces/:space_id/datasets/:id" do
    test "returns a dataset", %{conn: conn, space: space, dataset: dataset} do
      conn = get(conn, "/api/v1/spaces/#{space.id}/datasets/#{dataset.id}")
      assert %{"data" => data} = json_response(conn, 200)
      assert data["name"] == "Test Dataset"
      assert data["download_count"] == 0
    end
  end

  describe "POST /api/v1/spaces/:space_id/datasets" do
    test "creates a dataset", %{conn: conn, user: user, space: space} do
      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/spaces/#{space.id}/datasets", %{
          name: "New Dataset",
          slug: "new-dataset"
        })

      assert %{"data" => data} = json_response(conn, 201)
      assert data["name"] == "New Dataset"
    end
  end

  describe "PATCH /api/v1/spaces/:space_id/datasets/:id" do
    test "updates a dataset", %{conn: conn, user: user, space: space, dataset: dataset} do
      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> patch("/api/v1/spaces/#{space.id}/datasets/#{dataset.id}", %{description: "Updated"})

      assert %{"data" => data} = json_response(conn, 200)
      assert data["description"] == "Updated"
    end
  end

  describe "DELETE /api/v1/spaces/:space_id/datasets/:id" do
    test "deletes a dataset", %{conn: conn, user: user, space: space, dataset: dataset} do
      conn =
        conn
        |> api_auth_conn(user)
        |> delete("/api/v1/spaces/#{space.id}/datasets/#{dataset.id}")

      assert %{"data" => %{"message" => "Dataset deleted"}} = json_response(conn, 200)
    end
  end

  describe "GET /api/v1/spaces/:space_id/datasets/:dataset_id/files" do
    test "lists dataset files", %{conn: conn, space: space, dataset: dataset} do
      # Attach a file to the dataset
      blob = Cyanea.BlobsFixtures.blob_fixture()
      {:ok, _df} = Cyanea.Datasets.attach_file(dataset, blob.id, "data/test.csv", size: 100)

      conn = get(conn, "/api/v1/spaces/#{space.id}/datasets/#{dataset.id}/files")
      assert %{"data" => files} = json_response(conn, 200)
      assert length(files) == 1
      assert hd(files)["path"] == "data/test.csv"
    end
  end

  describe "POST /api/v1/spaces/:space_id/datasets/:dataset_id/files" do
    @tag :requires_s3
    test "uploads a file (requires MinIO)", %{
      conn: conn,
      user: user,
      space: space,
      dataset: dataset
    } do
      upload = %Plug.Upload{
        path: create_tmp_file("hello,world\n"),
        filename: "data.csv",
        content_type: "text/csv"
      }

      conn =
        conn
        |> api_auth_conn(user)
        |> post("/api/v1/spaces/#{space.id}/datasets/#{dataset.id}/files", %{file: upload})

      assert %{"data" => data} = json_response(conn, 201)
      assert data["path"] == "data.csv"
      assert data["mime_type"] == "text/csv"
    end

    test "returns 400 when no file provided", %{
      conn: conn,
      user: user,
      space: space,
      dataset: dataset
    } do
      conn =
        conn
        |> api_auth_conn(user)
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/spaces/#{space.id}/datasets/#{dataset.id}/files", %{})

      assert json_response(conn, 400)
    end

    test "returns error for unauthorized user", %{conn: conn, space: space, dataset: dataset} do
      other_user = Cyanea.AccountsFixtures.user_fixture()

      upload = %Plug.Upload{
        path: create_tmp_file("test\n"),
        filename: "data.csv",
        content_type: "text/csv"
      }

      conn =
        conn
        |> api_auth_conn(other_user)
        |> post("/api/v1/spaces/#{space.id}/datasets/#{dataset.id}/files", %{file: upload})

      assert json_response(conn, 403)
    end
  end

  describe "DELETE /api/v1/spaces/:space_id/datasets/:dataset_id/files/:file_id" do
    test "removes a file", %{conn: conn, user: user, space: space, dataset: dataset} do
      blob = Cyanea.BlobsFixtures.blob_fixture()
      {:ok, df} = Cyanea.Datasets.attach_file(dataset, blob.id, "data/test.csv", size: 100)

      conn =
        conn
        |> api_auth_conn(user)
        |> delete("/api/v1/spaces/#{space.id}/datasets/#{dataset.id}/files/#{df.id}")

      assert %{"data" => %{"message" => "File removed"}} = json_response(conn, 200)
    end
  end

  defp create_tmp_file(content) do
    path = Path.join(System.tmp_dir!(), "cyn_test_#{System.unique_integer([:positive])}")
    File.write!(path, content)
    path
  end
end
