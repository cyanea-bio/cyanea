defmodule CyaneaWeb.ActivityEventComponent do
  @moduledoc """
  Shared component for rendering a single activity event.
  Used across dashboard, explore, user profile, and space activity tabs.
  """
  use Phoenix.Component

  import CyaneaWeb.UIComponents
  use CyaneaWeb, :verified_routes

  attr :event, :map, required: true
  attr :class, :string, default: nil

  def activity_event(assigns) do
    ~H"""
    <div class={["flex items-start gap-3 py-2", @class]}>
      <.avatar
        name={actor_name(@event)}
        size={:xs}
      />
      <div class="min-w-0 flex-1 text-sm">
        <span class="font-medium text-slate-900 dark:text-white"><%= actor_name(@event) %></span>
        <span class="text-slate-500"><%= action_text(@event.action) %></span>
        <span :if={subject_label(@event)} class="font-medium text-primary">
          <%= subject_label(@event) %>
        </span>
        <span class="ml-1 text-xs text-slate-400">
          <%= CyaneaWeb.Formatters.format_relative(@event.inserted_at) %>
        </span>
      </div>
    </div>
    """
  end

  defp actor_name(%{actor: %{username: username}}) when is_binary(username), do: username
  defp actor_name(_), do: "someone"

  defp action_text("created_space"), do: "created space"
  defp action_text("updated_space"), do: "updated space"
  defp action_text("forked_space"), do: "forked space"
  defp action_text("starred_space"), do: "starred"
  defp action_text("created_notebook"), do: "created notebook in"
  defp action_text("updated_notebook"), do: "updated notebook in"
  defp action_text("created_protocol"), do: "created protocol in"
  defp action_text("updated_protocol"), do: "updated protocol in"
  defp action_text("created_dataset"), do: "created dataset in"
  defp action_text("uploaded_file"), do: "uploaded file to"
  defp action_text("created_discussion"), do: "opened discussion in"
  defp action_text("commented"), do: "commented in"
  defp action_text(other), do: other

  defp subject_label(%{metadata: %{"name" => name}}) when is_binary(name), do: name
  defp subject_label(%{subject_type: "space", metadata: %{"slug" => slug}}), do: slug
  defp subject_label(_), do: nil
end
