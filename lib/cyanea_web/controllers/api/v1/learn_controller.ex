defmodule CyaneaWeb.Api.V1.LearnController do
  use CyaneaWeb, :controller

  alias Cyanea.{Learn, Spaces}
  alias CyaneaWeb.Api.V1.ApiHelpers

  action_fallback CyaneaWeb.Api.V1.FallbackController

  plug CyaneaWeb.Plugs.RequireScope, [scope: "write"] when action in [:fork_unit, :complete_checkpoint]

  @doc "GET /api/v1/learn/tracks"
  def list_tracks(conn, _params) do
    tracks =
      Learn.list_published_tracks()
      |> Enum.map(&ApiHelpers.serialize_track/1)

    json(conn, %{data: tracks})
  end

  @doc "GET /api/v1/learn/tracks/:slug"
  def show_track(conn, %{"slug" => slug}) do
    case Learn.get_track_with_paths(slug) do
      nil ->
        {:error, :not_found}

      track ->
        json(conn, %{data: ApiHelpers.serialize_track(track)})
    end
  end

  @doc "GET /api/v1/learn/paths/:id"
  def show_path(conn, %{"id" => id}) do
    case Learn.get_path_with_units(id) do
      nil ->
        {:error, :not_found}

      path ->
        json(conn, %{data: ApiHelpers.serialize_path(path)})
    end
  end

  @doc "POST /api/v1/learn/units/:space_id/fork"
  def fork_unit(conn, %{"space_id" => space_id} = params) do
    user = conn.assigns.current_user

    with {:ok, space} <- fetch_space(space_id),
         true <- space.space_type == "learn" || {:error, :bad_request} do
      checkpoints_total = ApiHelpers.parse_int(params["checkpoints_total"], 0)

      case Learn.fork_learn_unit(user, space, checkpoints_total: checkpoints_total) do
        {:ok, %{fork: fork, progress: progress}} ->
          conn
          |> put_status(:created)
          |> json(%{data: %{fork: ApiHelpers.serialize_space(fork), progress: ApiHelpers.serialize_progress(progress)}})

        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  @doc "GET /api/v1/learn/progress"
  def my_progress(conn, _params) do
    user = conn.assigns.current_user
    progress = Learn.list_user_progress(user.id)

    json(conn, %{data: Enum.map(progress, &ApiHelpers.serialize_progress/1)})
  end

  @doc "GET /api/v1/learn/progress/completed"
  def completed_slugs(conn, _params) do
    user = conn.assigns.current_user
    slugs = Learn.completed_unit_slugs(user.id)

    json(conn, %{data: slugs})
  end

  @doc "PATCH /api/v1/learn/progress/:id/checkpoint"
  def complete_checkpoint(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Learn.get_progress(id) do
      nil ->
        {:error, :not_found}

      %{user_id: uid} when uid != user.id ->
        {:error, :forbidden}

      progress ->
        case Learn.complete_checkpoint(progress, progress.checkpoints_total) do
          {:ok, updated} ->
            json(conn, %{data: ApiHelpers.serialize_progress(updated)})

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  defp fetch_space(id) do
    try do
      {:ok, Spaces.get_space!(id)}
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end
end
