defmodule CyaneaWeb.Api.V1.ApiHelpers do
  @moduledoc """
  Shared serialization and pagination helpers for API v1 controllers.
  """

  def serialize_space(space) do
    %{
      id: space.id,
      name: space.name,
      slug: space.slug,
      description: space.description,
      visibility: space.visibility,
      license: space.license,
      archived: space.archived,
      tags: space.tags || [],
      star_count: space.star_count,
      fork_count: space.fork_count,
      owner_type: space.owner_type,
      owner_id: space.owner_id,
      owner_name: Cyanea.Spaces.owner_display(space),
      forked_from_id: space.forked_from_id,
      inserted_at: format_datetime(space.inserted_at),
      updated_at: format_datetime(space.updated_at)
    }
  end

  def serialize_notebook(notebook) do
    %{
      id: notebook.id,
      title: notebook.title,
      slug: notebook.slug,
      content: notebook.content,
      position: notebook.position,
      space_id: notebook.space_id,
      inserted_at: format_datetime(notebook.inserted_at),
      updated_at: format_datetime(notebook.updated_at)
    }
  end

  def serialize_protocol(protocol) do
    %{
      id: protocol.id,
      title: protocol.title,
      slug: protocol.slug,
      description: protocol.description,
      content: protocol.content,
      version: protocol.version,
      position: protocol.position,
      space_id: protocol.space_id,
      inserted_at: format_datetime(protocol.inserted_at),
      updated_at: format_datetime(protocol.updated_at)
    }
  end

  def serialize_dataset(dataset) do
    %{
      id: dataset.id,
      name: dataset.name,
      slug: dataset.slug,
      description: dataset.description,
      storage_type: dataset.storage_type,
      external_url: dataset.external_url,
      metadata: dataset.metadata,
      tags: dataset.tags || [],
      position: dataset.position,
      space_id: dataset.space_id,
      inserted_at: format_datetime(dataset.inserted_at),
      updated_at: format_datetime(dataset.updated_at)
    }
  end

  def serialize_dataset_file(df) do
    %{
      id: df.id,
      path: df.path,
      size: df.size,
      dataset_id: df.dataset_id,
      blob_id: df.blob_id,
      mime_type: if(Ecto.assoc_loaded?(df.blob) && df.blob, do: df.blob.mime_type),
      sha256: if(Ecto.assoc_loaded?(df.blob) && df.blob, do: df.blob.sha256),
      inserted_at: format_datetime(df.inserted_at),
      updated_at: format_datetime(df.updated_at)
    }
  end

  def serialize_user(user) do
    %{
      id: user.id,
      username: user.username,
      name: user.name,
      bio: user.bio,
      affiliation: user.affiliation,
      avatar_url: user.avatar_url,
      orcid_id: user.orcid_id,
      plan: user.plan,
      inserted_at: format_datetime(user.inserted_at)
    }
  end

  def serialize_organization(org) do
    %{
      id: org.id,
      name: org.name,
      slug: org.slug,
      description: org.description,
      verified: org.verified,
      inserted_at: format_datetime(org.inserted_at)
    }
  end

  def serialize_webhook(webhook) do
    %{
      id: webhook.id,
      url: webhook.url,
      events: webhook.events,
      active: webhook.active,
      description: webhook.description,
      space_id: webhook.space_id,
      inserted_at: format_datetime(webhook.inserted_at)
    }
  end

  def serialize_webhook_delivery(delivery) do
    %{
      id: delivery.id,
      event: delivery.event,
      status: delivery.status,
      response_status: delivery.response_status,
      attempts: delivery.attempts,
      completed_at: format_datetime(delivery.completed_at),
      inserted_at: format_datetime(delivery.inserted_at)
    }
  end

  def serialize_track(track) do
    base = %{
      id: track.id,
      title: track.title,
      slug: track.slug,
      description: track.description,
      icon: track.icon,
      position: track.position
    }

    if Ecto.assoc_loaded?(track.paths) do
      Map.put(base, :paths, Enum.map(track.paths, &serialize_path/1))
    else
      base
    end
  end

  def serialize_path(path) do
    base = %{
      id: path.id,
      title: path.title,
      slug: path.slug,
      description: path.description,
      position: path.position
    }

    if Ecto.assoc_loaded?(path.path_units) do
      base
      |> Map.put(:units, Enum.map(path.path_units, &serialize_path_unit/1))
      |> Map.put(:unit_count, length(path.path_units))
    else
      base
    end
  end

  def serialize_path_unit(path_unit) do
    base = %{
      id: path_unit.id,
      position: path_unit.position,
      estimated_minutes: path_unit.estimated_minutes
    }

    if Ecto.assoc_loaded?(path_unit.space) && path_unit.space do
      Map.put(base, :space, %{
        id: path_unit.space.id,
        name: path_unit.space.name,
        slug: path_unit.space.slug
      })
    else
      base
    end
  end

  def serialize_progress(progress) do
    %{
      id: progress.id,
      status: progress.status,
      checkpoints_total: progress.checkpoints_total,
      checkpoints_passed: progress.checkpoints_passed,
      space_id: progress.space_id,
      fork_space_id: progress.fork_space_id,
      started_at: format_datetime(progress.started_at),
      completed_at: format_datetime(progress.completed_at)
    }
  end

  @doc """
  Applies offset-based pagination to a list.
  """
  def paginate(items, params) do
    page = parse_int(params["page"], 1)
    per_page = parse_int(params["per_page"], 30) |> min(100)
    offset = (page - 1) * per_page

    paginated = items |> Enum.drop(offset) |> Enum.take(per_page)

    %{
      items: paginated,
      page: page,
      per_page: per_page,
      total: length(items)
    }
  end

  def format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  def format_errors(other), do: %{detail: inspect(other)}

  def parse_int(nil, default), do: default

  def parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} when n > 0 -> n
      _ -> default
    end
  end

  def parse_int(val, _default) when is_integer(val) and val > 0, do: val
  def parse_int(_, default), do: default

  defp format_datetime(nil), do: nil
  defp format_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp format_datetime(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
end
