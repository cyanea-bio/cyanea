defmodule CyaneaWeb.DiscussionLive.Index do
  use CyaneaWeb, :live_view

  alias Cyanea.Discussions
  alias CyaneaWeb.ContentHelpers

  @impl true
  def mount(params, _session, socket) do
    case ContentHelpers.mount_space(socket, params) do
      {:ok, socket} ->
        space = socket.assigns.space
        status_filter = Map.get(params, "status", nil)

        discussions =
          Discussions.list_space_discussions(space.id,
            status: status_filter
          )

        {:ok,
         assign(socket,
           page_title: "Discussions - #{space.name}",
           discussions: discussions,
           status_filter: status_filter || "all"
         )}

      {:error, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_event("filter-status", %{"status" => status}, socket) do
    space = socket.assigns.space
    filter = if status == "all", do: nil, else: status

    discussions = Discussions.list_space_discussions(space.id, status: filter)
    {:noreply, assign(socket, discussions: discussions, status_filter: status)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.breadcrumb>
        <:crumb navigate={~p"/#{@owner_name}"}><%= @owner_name %></:crumb>
        <:crumb navigate={~p"/#{@owner_name}/#{@space.slug}"}><%= @space.name %></:crumb>
        <:crumb>Discussions</:crumb>
      </.breadcrumb>

      <div class="mt-6 flex items-center justify-between">
        <h1 class="text-2xl font-bold text-slate-900 dark:text-white">Discussions</h1>
        <.link
          :if={@current_user}
          navigate={~p"/#{@owner_name}/#{@space.slug}/discussions/new"}
          class="inline-flex items-center gap-2 rounded-lg bg-primary px-3 py-2 text-sm font-medium text-white hover:bg-primary/90"
        >
          <.icon name="hero-plus" class="h-4 w-4" /> New discussion
        </.link>
      </div>

      <%!-- Status filter tabs --%>
      <div class="mt-4">
        <.tabs>
          <:tab active={@status_filter == "all"} click="filter-status" value="all">
            All
          </:tab>
          <:tab active={@status_filter == "open"} click="filter-status" value="open">
            Open
          </:tab>
          <:tab active={@status_filter == "closed"} click="filter-status" value="closed">
            Closed
          </:tab>
        </.tabs>
      </div>

      <%!-- Discussion list --%>
      <div class="mt-6">
        <.card padding="p-0">
          <div :if={@discussions != []} class="divide-y divide-slate-100 dark:divide-slate-700">
            <.link
              :for={discussion <- @discussions}
              navigate={~p"/#{@owner_name}/#{@space.slug}/discussions/#{discussion.id}"}
              class="flex items-center justify-between px-6 py-4 hover:bg-slate-50 dark:hover:bg-slate-700/50"
            >
              <div class="min-w-0 flex-1">
                <div class="flex items-center gap-2">
                  <.icon
                    name={if discussion.status == "open", do: "hero-chat-bubble-left-right", else: "hero-check-circle"}
                    class={"h-5 w-5 shrink-0 #{if discussion.status == "open", do: "text-emerald-500", else: "text-slate-400"}"}
                  />
                  <span class="font-medium text-slate-900 dark:text-white"><%= discussion.title %></span>
                  <.badge :if={discussion.status == "closed"} color={:gray} size={:xs}>Closed</.badge>
                </div>
                <div class="ml-7 mt-1 text-xs text-slate-500">
                  opened by <%= if discussion.author, do: discussion.author.username, else: "unknown" %>
                  · <%= CyaneaWeb.Formatters.format_relative(discussion.inserted_at) %>
                </div>
              </div>
              <div class="flex items-center gap-1 text-sm text-slate-500">
                <.icon name="hero-chat-bubble-left" class="h-4 w-4" />
                <span><%= discussion.comment_count %></span>
              </div>
            </.link>
          </div>
          <div :if={@discussions == []} class="px-6 py-12">
            <.empty_state
              icon="hero-chat-bubble-left-right"
              heading="No discussions yet."
              description="Start a conversation about this space."
            >
              <:action>
                <.link
                  :if={@current_user}
                  navigate={~p"/#{@owner_name}/#{@space.slug}/discussions/new"}
                  class="text-sm font-medium text-primary hover:text-primary/80"
                >
                  Start a discussion
                </.link>
              </:action>
            </.empty_state>
          </div>
        </.card>
      </div>
    </div>
    """
  end
end
