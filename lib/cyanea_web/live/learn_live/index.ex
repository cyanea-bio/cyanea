defmodule CyaneaWeb.LearnLive.Index do
  use CyaneaWeb, :live_view

  alias Cyanea.Learn

  @impl true
  def mount(_params, _session, socket) do
    tracks = Learn.list_published_tracks_with_paths()

    {:ok,
     assign(socket,
       page_title: "Learn",
       tracks: tracks
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl">
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-slate-900 dark:text-white">Learn</h1>
        <p class="mt-2 text-slate-600 dark:text-slate-400">
          Interactive bioinformatics courses with hands-on exercises. Fork units to your workspace and track your progress.
        </p>
      </div>

      <div :if={@tracks == []} class="rounded-lg border border-slate-200 bg-white p-12 text-center dark:border-slate-700 dark:bg-slate-800">
        <p class="text-slate-500">No learning tracks available yet.</p>
      </div>

      <div class="space-y-8">
        <div :for={track <- @tracks} class="rounded-lg border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-800">
          <div class="border-b border-slate-200 p-6 dark:border-slate-700">
            <div class="flex items-center gap-3">
              <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
                <.track_icon icon={track.icon} />
              </div>
              <div>
                <h2 class="text-lg font-semibold text-slate-900 dark:text-white">
                  <%= track.title %>
                </h2>
                <p class="text-sm text-slate-500"><%= track.description %></p>
              </div>
            </div>
          </div>

          <div :if={track.paths == []} class="p-6 text-center text-sm text-slate-500">
            Coming soon
          </div>

          <div :if={track.paths != []} class="divide-y divide-slate-100 dark:divide-slate-700">
            <.link
              :for={path <- track.paths}
              navigate={~p"/learn/#{track.slug}/#{path.slug}"}
              class="flex items-center justify-between p-4 hover:bg-slate-50 dark:hover:bg-slate-700/50"
            >
              <div>
                <h3 class="font-medium text-slate-900 dark:text-white"><%= path.title %></h3>
                <p class="mt-0.5 text-sm text-slate-500"><%= path.description %></p>
              </div>
              <.icon name="hero-chevron-right" class="h-5 w-5 flex-shrink-0 text-slate-400" />
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp track_icon(%{icon: "dna"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="h-5 w-5">
      <path d="M10 2a.75.75 0 01.75.75v1.5a.75.75 0 01-1.5 0v-1.5A.75.75 0 0110 2zM10 15a.75.75 0 01.75.75v1.5a.75.75 0 01-1.5 0v-1.5A.75.75 0 0110 15zM10 7a3 3 0 100 6 3 3 0 000-6zM15.657 5.404a.75.75 0 10-1.06-1.06l-1.061 1.06a.75.75 0 001.06 1.06l1.06-1.06zM6.464 14.596a.75.75 0 10-1.06-1.06l-1.06 1.06a.75.75 0 001.06 1.06l1.06-1.06zM18 10a.75.75 0 01-.75.75h-1.5a.75.75 0 010-1.5h1.5A.75.75 0 0118 10zM5 10a.75.75 0 01-.75.75h-1.5a.75.75 0 010-1.5h1.5A.75.75 0 015 10z"/>
    </svg>
    """
  end

  defp track_icon(%{icon: "cell"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="h-5 w-5">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clip-rule="evenodd"/>
    </svg>
    """
  end

  defp track_icon(assigns) do
    ~H"""
    <.icon name="hero-academic-cap" class="h-5 w-5" />
    """
  end
end
