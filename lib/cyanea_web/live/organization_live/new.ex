defmodule CyaneaWeb.OrganizationLive.New do
  use CyaneaWeb, :live_view

  alias Cyanea.Organizations
  alias Cyanea.Organizations.Organization

  @impl true
  def mount(_params, _session, socket) do
    changeset = Organizations.change_organization(%Organization{})

    {:ok,
     assign(socket,
       page_title: "New Organization",
       form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("validate", %{"organization" => org_params}, socket) do
    changeset =
      %Organization{}
      |> Organizations.change_organization(org_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"organization" => org_params}, socket) do
    user = socket.assigns.current_user
    org_params = maybe_generate_slug(org_params)

    case Organizations.create_organization(org_params, user.id) do
      {:ok, org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organization created successfully!")
         |> push_navigate(to: ~p"/#{org.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp maybe_generate_slug(%{"slug" => slug} = params) when slug != "" and slug != nil, do: params

  defp maybe_generate_slug(%{"name" => name} = params) when is_binary(name) do
    slug =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9-]+/, "-")
      |> String.trim("-")

    Map.put(params, "slug", slug)
  end

  defp maybe_generate_slug(params), do: params

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header>
        Create a new organization
        <:subtitle>Organizations let teams manage repositories and collaborate together.</:subtitle>
      </.header>

      <div class="mt-8 rounded-xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <.simple_form for={@form} phx-change="validate" phx-submit="save">
          <.input field={@form[:name]} type="text" label="Organization name" required placeholder="My Lab" />
          <.input field={@form[:slug]} type="text" label="Slug" required placeholder="my-lab" />
          <.input field={@form[:description]} type="textarea" label="Description" placeholder="What does your organization do?" rows="3" />
          <.input field={@form[:website]} type="url" label="Website" placeholder="https://..." />
          <.input field={@form[:location]} type="text" label="Location" placeholder="City, Country" />
          <.input field={@form[:avatar_url]} type="url" label="Avatar URL" placeholder="https://..." />

          <:actions>
            <.link navigate={~p"/dashboard"} class="text-sm font-medium text-slate-600 hover:text-slate-900 dark:text-slate-400">
              Cancel
            </.link>
            <.button type="submit" phx-disable-with="Creating...">Create organization</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
