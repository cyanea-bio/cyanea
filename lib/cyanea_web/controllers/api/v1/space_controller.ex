defmodule CyaneaWeb.Api.V1.SpaceController do
  use CyaneaWeb, :controller

  alias Cyanea.{Organizations, Spaces}
  alias CyaneaWeb.Api.V1.ApiHelpers

  action_fallback CyaneaWeb.Api.V1.FallbackController

  plug CyaneaWeb.Plugs.RequireScope, [scope: "write"] when action in [:create, :update, :delete, :fork]

  @doc "GET /api/v1/spaces"
  def index(conn, params) do
    spaces = Spaces.list_public_spaces(limit: ApiHelpers.parse_int(params["limit"], 50))
    result = ApiHelpers.paginate(Enum.map(spaces, &ApiHelpers.serialize_space/1), params)

    json(conn, %{data: result.items, meta: %{page: result.page, per_page: result.per_page, total: result.total}})
  end

  @doc "GET /api/v1/spaces/:id"
  def show(conn, %{"id" => id}) do
    try do
      space = Spaces.get_space!(id)
      user = conn.assigns[:current_user]

      if Spaces.can_access?(space, user) do
        json(conn, %{data: ApiHelpers.serialize_space(space)})
      else
        conn |> put_status(:not_found) |> json(%{error: %{status: 404, message: "Space not found"}})
      end
    rescue
      Ecto.NoResultsError ->
        conn |> put_status(:not_found) |> json(%{error: %{status: 404, message: "Space not found"}})
    end
  end

  @doc "GET /api/v1/:owner/:slug"
  def show_by_slug(conn, %{"owner" => owner, "slug" => slug}) do
    case Spaces.get_space_by_owner_and_slug(owner, slug) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: %{status: 404, message: "Space not found"}})

      space ->
        user = conn.assigns[:current_user]

        if Spaces.can_access?(space, user) do
          json(conn, %{data: ApiHelpers.serialize_space(space)})
        else
          conn |> put_status(:not_found) |> json(%{error: %{status: 404, message: "Space not found"}})
        end
    end
  end

  @doc "POST /api/v1/spaces"
  def create(conn, params) do
    user = conn.assigns.current_user

    attrs = %{
      name: params["name"],
      slug: params["slug"],
      description: params["description"],
      visibility: params["visibility"] || "public",
      license: params["license"],
      tags: params["tags"] || [],
      owner_type: params["owner_type"] || "user",
      owner_id: params["owner_id"] || user.id
    }

    # Verify ownership authorization
    with :ok <- authorize_owner(user, attrs.owner_type, attrs.owner_id),
         {:ok, space} <- Spaces.create_space(attrs) do
      conn
      |> put_status(:created)
      |> json(%{data: ApiHelpers.serialize_space(space)})
    else
      {:error, :unauthorized} ->
        conn |> put_status(:forbidden) |> json(%{error: %{status: 403, message: "Not authorized to create spaces for this owner"}})

      {:error, :pro_required} ->
        conn |> put_status(:forbidden) |> json(%{error: %{status: 403, message: "Pro plan required for private spaces"}})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: %{status: 422, message: "Validation failed", details: ApiHelpers.format_errors(changeset)}})
    end
  end

  @doc "PATCH /api/v1/spaces/:id"
  def update(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user

    with {:ok, space} <- fetch_space(id),
         :ok <- authorize_write(space, user) do
      attrs =
        params
        |> Map.take(["name", "slug", "description", "visibility", "license", "tags", "archived", "readme"])
        |> atomize_keys()

      case Spaces.update_space(space, attrs) do
        {:ok, space} ->
          json(conn, %{data: ApiHelpers.serialize_space(space)})

        {:error, :pro_required} ->
          conn |> put_status(:forbidden) |> json(%{error: %{status: 403, message: "Pro plan required for private spaces"}})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: %{status: 422, message: "Validation failed", details: ApiHelpers.format_errors(changeset)}})
      end
    end
  end

  @doc "DELETE /api/v1/spaces/:id"
  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, space} <- fetch_space(id),
         :ok <- authorize_write(space, user),
         {:ok, _space} <- Spaces.delete_space(space) do
      json(conn, %{data: %{message: "Space deleted"}})
    end
  end

  @doc "POST /api/v1/spaces/:id/fork"
  def fork(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user

    with {:ok, space} <- fetch_space(id),
         true <- Spaces.can_access?(space, user) || {:error, :not_found} do
      attrs = Map.take(params, ["name", "slug"])

      case Spaces.fork_space(space, user, atomize_keys(attrs)) do
        {:ok, forked} ->
          conn
          |> put_status(:created)
          |> json(%{data: ApiHelpers.serialize_space(forked)})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: %{status: 422, message: "Fork failed", details: ApiHelpers.format_errors(changeset)}})
      end
    end
  end

  ## Private helpers

  defp fetch_space(id) do
    try do
      {:ok, Spaces.get_space!(id)}
    rescue
      Ecto.NoResultsError ->
        {:error, :not_found}
    end
  end

  defp authorize_write(space, user) do
    cond do
      Spaces.owner?(space, user) ->
        :ok

      space.owner_type == "organization" ->
        case Organizations.authorize(user.id, space.owner_id, "admin") do
          {:ok, _} -> :ok
          {:error, _} -> {:error, :forbidden}
        end

      true ->
        {:error, :forbidden}
    end
  end

  defp authorize_owner(user, "user", owner_id) do
    if user.id == owner_id, do: :ok, else: {:error, :unauthorized}
  end

  defp authorize_owner(user, "organization", org_id) do
    case Organizations.authorize(user.id, org_id, "admin") do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :unauthorized}
    end
  end

  defp authorize_owner(_, _, _), do: {:error, :unauthorized}

  defp atomize_keys(map) do
    Map.new(map, fn {k, v} -> {String.to_existing_atom(k), v} end)
  rescue
    ArgumentError -> Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

end
