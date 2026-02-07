defmodule CyaneaWeb.ArtifactLive.New do
  use CyaneaWeb, :live_view

  alias Cyanea.Repositories
  alias Cyanea.Artifacts
  alias Cyanea.Artifacts.Artifact

  @impl true
  def mount(%{"username" => owner_name, "slug" => repo_slug}, _session, socket) do
    repo =
      Repositories.get_repository_by_owner_and_slug(owner_name, repo_slug) ||
        Repositories.get_repository_by_org_and_slug(owner_name, repo_slug)

    current_user = socket.assigns.current_user

    cond do
      is_nil(repo) ->
        {:ok,
         socket
         |> put_flash(:error, "Repository not found.")
         |> redirect(to: ~p"/explore")}

      not is_repo_owner?(repo, current_user) ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have permission to create artifacts here.")
         |> redirect(to: ~p"/#{owner_name}/#{repo_slug}")}

      true ->
        changeset = Artifact.changeset(%Artifact{}, %{type: "dataset", visibility: "public"})

        {:ok,
         assign(socket,
           page_title: "New Artifact",
           repo: repo,
           owner_name: owner_name,
           form: to_form(changeset)
         )}
    end
  end

  @impl true
  def handle_event("validate", %{"artifact" => params}, socket) do
    changeset =
      %Artifact{}
      |> Artifact.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"artifact" => params}, socket) do
    user = socket.assigns.current_user
    repo = socket.assigns.repo
    owner_name = socket.assigns.owner_name

    params =
      params
      |> Map.put("author_id", user.id)
      |> Map.put("repository_id", repo.id)
      |> maybe_generate_slug()

    case Artifacts.create_artifact(params) do
      {:ok, artifact} ->
        {:noreply,
         socket
         |> put_flash(:info, "Artifact created successfully!")
         |> push_navigate(to: ~p"/#{owner_name}/#{repo.slug}/artifacts/#{artifact.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp maybe_generate_slug(%{"slug" => slug} = params) when slug != "" and slug != nil, do: params

  defp maybe_generate_slug(%{"name" => name} = params) when is_binary(name) do
    slug =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9._-]+/, "-")
      |> String.trim("-")

    Map.put(params, "slug", slug)
  end

  defp maybe_generate_slug(params), do: params

  defp is_repo_owner?(repo, user) do
    repo.owner_id == user.id
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header>
        New artifact
        <:subtitle>
          Add a dataset, protocol, notebook, or other research artifact to
          <span class="font-semibold"><%= @owner_name %>/<%= @repo.name %></span>.
        </:subtitle>
      </.header>

      <div class="mt-8 rounded-xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <.simple_form for={@form} phx-change="validate" phx-submit="save">
          <.input
            field={@form[:type]}
            type="select"
            label="Type"
            options={[
              {"Dataset", "dataset"},
              {"Protocol", "protocol"},
              {"Notebook", "notebook"},
              {"Pipeline", "pipeline"},
              {"Result", "result"},
              {"Sample", "sample"}
            ]}
          />

          <.input field={@form[:name]} type="text" label="Name" required placeholder="raw-counts" />
          <.input field={@form[:slug]} type="text" label="Slug" placeholder="raw-counts" />
          <.input
            field={@form[:description]}
            type="textarea"
            label="Description"
            placeholder="Describe this artifact — what it contains, how it was generated."
            rows="3"
          />

          <.input field={@form[:version]} type="text" label="Version" placeholder="1.0.0" />

          <.input
            field={@form[:visibility]}
            type="select"
            label="Visibility"
            options={[{"Public", "public"}, {"Internal", "internal"}, {"Private", "private"}]}
          />

          <.input
            field={@form[:license]}
            type="select"
            label="License"
            prompt="Choose a license (optional)"
            options={[
              {"CC BY 4.0", "cc-by-4.0"},
              {"CC BY-SA 4.0", "cc-by-sa-4.0"},
              {"CC0 1.0 (Public Domain)", "cc0-1.0"},
              {"MIT", "mit"},
              {"Apache 2.0", "apache-2.0"},
              {"Proprietary", "proprietary"}
            ]}
          />

          <:actions>
            <.link
              navigate={~p"/#{@owner_name}/#{@repo.slug}"}
              class="text-sm font-medium text-slate-600 hover:text-slate-900 dark:text-slate-400"
            >
              Cancel
            </.link>
            <.button type="submit" phx-disable-with="Creating...">Create artifact</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
