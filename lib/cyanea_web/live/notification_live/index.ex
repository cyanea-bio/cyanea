defmodule CyaneaWeb.NotificationLive.Index do
  use CyaneaWeb, :live_view

  alias Cyanea.Notifications

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    notifications = Notifications.list_all(user.id)
    unread_count = Notifications.unread_count(user.id)

    {:ok,
     assign(socket,
       page_title: "Notifications",
       notifications: notifications,
       unread_count: unread_count
     )}
  end

  @impl true
  def handle_event("mark-read", %{"id" => id}, socket) do
    Notifications.mark_read(id)
    notifications = Notifications.list_all(socket.assigns.current_user.id)
    unread_count = Notifications.unread_count(socket.assigns.current_user.id)
    {:noreply, assign(socket, notifications: notifications, unread_count: unread_count)}
  end

  def handle_event("mark-all-read", _params, socket) do
    Notifications.mark_all_read(socket.assigns.current_user.id)
    notifications = Notifications.list_all(socket.assigns.current_user.id)
    {:noreply, assign(socket, notifications: notifications, unread_count: 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between">
        <.header>
          Notifications
          <:subtitle>
            <%= if @unread_count > 0, do: "#{@unread_count} unread", else: "All caught up" %>
          </:subtitle>
        </.header>
        <button
          :if={@unread_count > 0}
          phx-click="mark-all-read"
          class="rounded-lg border border-slate-200 px-3 py-1.5 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
        >
          Mark all as read
        </button>
      </div>

      <div class="mt-6 space-y-2">
        <div
          :for={notification <- @notifications}
          class={[
            "flex items-center justify-between rounded-lg border px-4 py-3 transition",
            if(is_nil(notification.read_at),
              do: "border-primary/20 bg-primary/5 dark:border-primary/30 dark:bg-primary/10",
              else: "border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-800"
            )
          ]}
        >
          <div class="flex items-center gap-3">
            <.avatar
              name={if notification.actor, do: notification.actor.username, else: "?"}
              size={:sm}
            />
            <div class="text-sm">
              <span class="font-medium text-slate-900 dark:text-white">
                <%= if notification.actor, do: notification.actor.username, else: "Someone" %>
              </span>
              <span class="text-slate-500"><%= notification_text(notification.action) %></span>
              <span class="ml-1 text-xs text-slate-400">
                <%= CyaneaWeb.Formatters.format_relative(notification.inserted_at) %>
              </span>
            </div>
          </div>
          <button
            :if={is_nil(notification.read_at)}
            phx-click="mark-read"
            phx-value-id={notification.id}
            class="shrink-0 text-xs text-primary hover:text-primary/80"
          >
            Mark read
          </button>
        </div>

        <.empty_state
          :if={@notifications == []}
          icon="hero-bell"
          heading="No notifications yet."
          description="You'll be notified when someone interacts with your content."
        />
      </div>
    </div>
    """
  end

  defp notification_text("starred"), do: "starred your space"
  defp notification_text("forked"), do: "forked your space"
  defp notification_text("new_discussion"), do: "opened a discussion in your space"
  defp notification_text("new_comment"), do: "commented on a discussion"
  defp notification_text("mentioned"), do: "mentioned you"
  defp notification_text(other), do: other
end
