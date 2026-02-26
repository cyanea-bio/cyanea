defmodule CyaneaWeb.DiscussionLive.Show do
  use CyaneaWeb, :live_view

  alias Cyanea.Activity
  alias Cyanea.Discussions
  alias Cyanea.Notifications
  alias CyaneaWeb.ContentHelpers

  @impl true
  def mount(%{"discussion_id" => discussion_id} = params, _session, socket) do
    case ContentHelpers.mount_space(socket, params) do
      {:ok, socket} ->
        {discussion, comments} = Discussions.get_discussion_with_comments(discussion_id)

        {:ok,
         assign(socket,
           page_title: discussion.title,
           discussion: discussion,
           comments: comments,
           comment_body: "",
           reply_to: nil,
           reply_body: ""
         )}

      {:error, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_event("add-comment", %{"body" => body}, socket) do
    discussion = socket.assigns.discussion
    user = socket.assigns.current_user

    case Discussions.add_comment(discussion, user, %{body: body}) do
      {:ok, _comment} ->
        Activity.log(user, "commented", discussion,
          space_id: socket.assigns.space.id,
          metadata: %{"name" => discussion.title}
        )

        Notifications.notify_discussion_participants(
          user,
          "new_comment",
          discussion,
          "discussion",
          discussion.id
        )

        {discussion, comments} = Discussions.get_discussion_with_comments(discussion.id)

        {:noreply,
         assign(socket,
           discussion: discussion,
           comments: comments,
           comment_body: ""
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add comment.")}
    end
  end

  def handle_event("reply", %{"parent-id" => parent_id, "body" => body}, socket) do
    discussion = socket.assigns.discussion
    user = socket.assigns.current_user

    case Discussions.add_comment(discussion, user, %{
           body: body,
           parent_comment_id: parent_id
         }) do
      {:ok, _comment} ->
        Activity.log(user, "commented", discussion,
          space_id: socket.assigns.space.id,
          metadata: %{"name" => discussion.title}
        )

        Notifications.notify_discussion_participants(
          user,
          "new_comment",
          discussion,
          "discussion",
          discussion.id
        )

        {discussion, comments} = Discussions.get_discussion_with_comments(discussion.id)

        {:noreply,
         assign(socket,
           discussion: discussion,
           comments: comments,
           reply_to: nil,
           reply_body: ""
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to reply.")}
    end
  end

  def handle_event("show-reply", %{"id" => comment_id}, socket) do
    {:noreply, assign(socket, reply_to: comment_id, reply_body: "")}
  end

  def handle_event("cancel-reply", _params, socket) do
    {:noreply, assign(socket, reply_to: nil, reply_body: "")}
  end

  def handle_event("close-discussion", _params, socket) do
    case Discussions.close_discussion(socket.assigns.discussion) do
      {:ok, discussion} ->
        {:noreply, assign(socket, discussion: discussion)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to close discussion.")}
    end
  end

  def handle_event("reopen-discussion", _params, socket) do
    case Discussions.reopen_discussion(socket.assigns.discussion) do
      {:ok, discussion} ->
        {:noreply, assign(socket, discussion: discussion)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reopen discussion.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.breadcrumb>
        <:crumb navigate={~p"/#{@owner_name}"}><%= @owner_name %></:crumb>
        <:crumb navigate={~p"/#{@owner_name}/#{@space.slug}"}><%= @space.name %></:crumb>
        <:crumb navigate={~p"/#{@owner_name}/#{@space.slug}/discussions"}>Discussions</:crumb>
        <:crumb><%= @discussion.title %></:crumb>
      </.breadcrumb>

      <%!-- Discussion header --%>
      <div class="mt-6">
        <div class="flex items-start justify-between">
          <div>
            <h1 class="text-2xl font-bold text-slate-900 dark:text-white"><%= @discussion.title %></h1>
            <div class="mt-2 flex items-center gap-2 text-sm text-slate-500">
              <.badge :if={@discussion.status == "open"} color={:success}>Open</.badge>
              <.badge :if={@discussion.status == "closed"} color={:gray}>Closed</.badge>
              <span>
                opened by <%= if @discussion.author, do: @discussion.author.username, else: "unknown" %>
                · <%= CyaneaWeb.Formatters.format_relative(@discussion.inserted_at) %>
              </span>
            </div>
          </div>
          <%= if can_manage?(@discussion, @space, @current_user) do %>
            <%= if @discussion.status == "open" do %>
              <button
                phx-click="close-discussion"
                class="rounded-lg border border-slate-200 px-3 py-1.5 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
              >
                Close discussion
              </button>
            <% else %>
              <button
                phx-click="reopen-discussion"
                class="rounded-lg border border-slate-200 px-3 py-1.5 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
              >
                Reopen discussion
              </button>
            <% end %>
          <% end %>
        </div>
      </div>

      <%!-- Discussion body --%>
      <.card class="mt-6">
        <div class="flex items-start gap-3">
          <.avatar
            name={if @discussion.author, do: @discussion.author.username, else: "?"}
            size={:sm}
          />
          <div class="min-w-0 flex-1">
            <div class="text-sm font-medium text-slate-900 dark:text-white">
              <%= if @discussion.author, do: @discussion.author.username, else: "unknown" %>
            </div>
            <div class="mt-2 prose prose-sm dark:prose-invert max-w-none">
              <%= raw(render_markdown(@discussion.body)) %>
            </div>
          </div>
        </div>
      </.card>

      <%!-- Comments --%>
      <div class="mt-6 space-y-4">
        <h3 class="text-sm font-semibold text-slate-900 dark:text-white">
          <%= @discussion.comment_count %> comment(s)
        </h3>

        <div :for={comment <- @comments} class="space-y-3">
          <%!-- Top-level comment --%>
          <.card>
            <div class="flex items-start gap-3">
              <.avatar
                name={if comment.author, do: comment.author.username, else: "?"}
                size={:sm}
              />
              <div class="min-w-0 flex-1">
                <div class="flex items-center gap-2">
                  <span class="text-sm font-medium text-slate-900 dark:text-white">
                    <%= if comment.author, do: comment.author.username, else: "unknown" %>
                  </span>
                  <span class="text-xs text-slate-400">
                    <%= CyaneaWeb.Formatters.format_relative(comment.inserted_at) %>
                  </span>
                </div>
                <div class="mt-1 prose prose-sm dark:prose-invert max-w-none">
                  <%= raw(render_markdown(comment.body)) %>
                </div>
                <button
                  :if={@current_user}
                  phx-click="show-reply"
                  phx-value-id={comment.id}
                  class="mt-2 text-xs text-primary hover:text-primary/80"
                >
                  Reply
                </button>
              </div>
            </div>

            <%!-- Replies --%>
            <div :for={reply <- comment.replies} class="ml-10 mt-4 border-l-2 border-slate-100 pl-4 dark:border-slate-700">
              <div class="flex items-start gap-3">
                <.avatar
                  name={if reply.author, do: reply.author.username, else: "?"}
                  size={:xs}
                />
                <div class="min-w-0 flex-1">
                  <div class="flex items-center gap-2">
                    <span class="text-sm font-medium text-slate-900 dark:text-white">
                      <%= if reply.author, do: reply.author.username, else: "unknown" %>
                    </span>
                    <span class="text-xs text-slate-400">
                      <%= CyaneaWeb.Formatters.format_relative(reply.inserted_at) %>
                    </span>
                  </div>
                  <div class="mt-1 prose prose-sm dark:prose-invert max-w-none">
                    <%= raw(render_markdown(reply.body)) %>
                  </div>
                </div>
              </div>
            </div>

            <%!-- Inline reply form --%>
            <div :if={@reply_to == comment.id && @current_user} class="ml-10 mt-4">
              <form phx-submit="reply" class="space-y-2">
                <input type="hidden" name="parent-id" value={comment.id} />
                <textarea
                  name="body"
                  rows="3"
                  placeholder="Write a reply..."
                  class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                ><%= @reply_body %></textarea>
                <div class="flex gap-2">
                  <.button type="submit" class="text-xs px-3 py-1.5">Reply</.button>
                  <button type="button" phx-click="cancel-reply" class="text-sm text-slate-500 hover:text-slate-700">
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          </.card>
        </div>
      </div>

      <%!-- New comment form --%>
      <div :if={@current_user && @discussion.status == "open"} class="mt-6">
        <.card>
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Add a comment</h3>
          <form phx-submit="add-comment" class="mt-3 space-y-3">
            <textarea
              name="body"
              rows="4"
              placeholder="Write a comment..."
              class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
            ><%= @comment_body %></textarea>
            <.button type="submit" phx-disable-with="Posting...">Comment</.button>
          </form>
        </.card>
      </div>

      <div :if={@discussion.status == "closed"} class="mt-6">
        <p class="text-center text-sm text-slate-500">This discussion is closed.</p>
      </div>
    </div>
    """
  end

  defp can_manage?(discussion, space, user) do
    user != nil &&
      (Cyanea.Spaces.owner?(space, user) ||
         (discussion.author_id != nil && discussion.author_id == user.id))
  end

  defp render_markdown(nil), do: ""

  defp render_markdown(text) do
    case CyaneaWeb.Markdown.render(text) do
      {:safe, html} -> html
      html when is_binary(html) -> html
    end
  end
end
