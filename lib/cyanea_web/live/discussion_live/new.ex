defmodule CyaneaWeb.DiscussionLive.New do
  use CyaneaWeb, :live_view

  alias Cyanea.Activity
  alias Cyanea.Discussions
  alias Cyanea.Notifications
  alias CyaneaWeb.ContentHelpers

  @impl true
  def mount(params, _session, socket) do
    case ContentHelpers.mount_space(socket, params) do
      {:ok, socket} ->
        changeset = Discussions.change_discussion(%Cyanea.Discussions.Discussion{})

        {:ok,
         assign(socket,
           page_title: "New Discussion - #{socket.assigns.space.name}",
           form: to_form(changeset)
         )}

      {:error, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"discussion" => params}, socket) do
    changeset =
      %Cyanea.Discussions.Discussion{}
      |> Discussions.change_discussion(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"discussion" => params}, socket) do
    space = socket.assigns.space
    user = socket.assigns.current_user

    case Discussions.create_discussion(space, user, params) do
      {:ok, discussion} ->
        Activity.log(user, "created_discussion", discussion,
          space_id: space.id,
          metadata: %{"name" => discussion.title}
        )

        Notifications.notify_space_owner(
          user,
          "new_discussion",
          space,
          "discussion",
          discussion.id
        )

        {:noreply,
         socket
         |> put_flash(:info, "Discussion created.")
         |> redirect(
           to:
             ~p"/#{socket.assigns.owner_name}/#{space.slug}/discussions/#{discussion.id}"
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
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
        <:crumb>New</:crumb>
      </.breadcrumb>

      <div class="mt-6">
        <h1 class="text-2xl font-bold text-slate-900 dark:text-white">New Discussion</h1>
      </div>

      <.card class="mt-6">
        <.simple_form for={@form} phx-change="validate" phx-submit="save">
          <.input field={@form[:title]} label="Title" placeholder="What would you like to discuss?" />
          <.input
            field={@form[:body]}
            label="Body"
            type="textarea"
            rows="8"
            placeholder="Write your discussion body here. Markdown is supported."
          />
          <:actions>
            <.button type="submit" phx-disable-with="Creating...">Create discussion</.button>
            <.link
              navigate={~p"/#{@owner_name}/#{@space.slug}/discussions"}
              class="text-sm text-slate-500 hover:text-slate-700"
            >
              Cancel
            </.link>
          </:actions>
        </.simple_form>
      </.card>
    </div>
    """
  end
end
