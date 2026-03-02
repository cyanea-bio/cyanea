defmodule CyaneaWeb.LearnLive.Path do
  use CyaneaWeb, :live_view

  alias Cyanea.Learn

  @impl true
  def mount(%{"track_slug" => track_slug, "path_slug" => path_slug}, _session, socket) do
    case Learn.get_path_by_slugs(track_slug, path_slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Learning path not found.")
         |> redirect(to: ~p"/learn")}

      path ->
        current_user = socket.assigns[:current_user]

        progress_map =
          if current_user do
            space_ids = Enum.map(path.path_units, & &1.space_id)
            Learn.user_progress_for_units(current_user.id, space_ids)
          else
            %{}
          end

        total_minutes =
          path.path_units
          |> Enum.map(& &1.estimated_minutes)
          |> Enum.reject(&is_nil/1)
          |> Enum.sum()

        {:ok,
         assign(socket,
           page_title: "#{path.title} - Learn",
           path: path,
           track: path.track,
           progress_map: progress_map,
           total_minutes: total_minutes
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl">
      <nav class="mb-6" aria-label="Breadcrumb">
        <ol class="flex items-center gap-2 text-sm text-slate-500">
          <li><.link navigate={~p"/learn"} class="hover:text-primary">Learn</.link></li>
          <li><.icon name="hero-chevron-right" class="h-3.5 w-3.5" /></li>
          <li><%= @track.title %></li>
          <li><.icon name="hero-chevron-right" class="h-3.5 w-3.5" /></li>
          <li class="text-slate-900 dark:text-white"><%= @path.title %></li>
        </ol>
      </nav>

      <div class="mb-8">
        <h1 class="text-2xl font-bold text-slate-900 dark:text-white"><%= @path.title %></h1>
        <p class="mt-2 text-slate-600 dark:text-slate-400"><%= @path.description %></p>
        <div class="mt-3 flex items-center gap-4 text-sm text-slate-500">
          <span><%= length(@path.path_units) %> units</span>
          <span :if={@total_minutes > 0}><%= @total_minutes %> min total</span>
        </div>
      </div>

      <div class="space-y-3">
        <div
          :for={{unit, idx} <- Enum.with_index(@path.path_units)}
          class="rounded-lg border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-800"
        >
          <div class="flex items-start gap-4">
            <div class={[
              "flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full text-sm font-medium",
              unit_status_class(Map.get(@progress_map, unit.space_id))
            ]}>
              <%= if Map.get(@progress_map, unit.space_id) == "completed" do %>
                <.icon name="hero-check" class="h-4 w-4" />
              <% else %>
                <%= idx + 1 %>
              <% end %>
            </div>

            <div class="flex-1">
              <.link
                navigate={space_learn_path(unit.space)}
                class="font-medium text-slate-900 hover:text-primary dark:text-white"
              >
                <%= unit.space.name %>
              </.link>
              <p :if={unit.space.description} class="mt-0.5 text-sm text-slate-500">
                <%= unit.space.description %>
              </p>
              <div class="mt-1 flex items-center gap-3 text-xs text-slate-400">
                <span :if={unit.estimated_minutes}><%= unit.estimated_minutes %> min</span>
                <.progress_label status={Map.get(@progress_map, unit.space_id)} />
              </div>
            </div>

            <.link
              navigate={space_learn_path(unit.space)}
              class="flex-shrink-0 rounded-lg border border-slate-200 px-3 py-1.5 text-sm font-medium hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
            >
              <%= case Map.get(@progress_map, unit.space_id) do %>
                <% "completed" -> %>Resume
                <% "in_progress" -> %>Continue
                <% _ -> %>Start
              <% end %>
            </.link>
          </div>
        </div>

        <div :if={@path.path_units == []}>
          <p class="text-center text-slate-500">No units in this path yet.</p>
        </div>
      </div>
    </div>
    """
  end

  defp unit_status_class("completed"),
    do: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"

  defp unit_status_class("in_progress"),
    do: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400"

  defp unit_status_class(_),
    do: "bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-400"

  defp progress_label(%{status: "completed"} = assigns) do
    ~H"""
    <span class="text-green-600 dark:text-green-400">Completed</span>
    """
  end

  defp progress_label(%{status: "in_progress"} = assigns) do
    ~H"""
    <span class="text-blue-600 dark:text-blue-400">In progress</span>
    """
  end

  defp progress_label(assigns) do
    ~H"""
    """
  end

  defp space_learn_path(space) do
    owner = Cyanea.Spaces.owner_display(space)
    ~p"/#{owner}/#{space.slug}"
  end
end
