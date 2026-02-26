defmodule CyaneaWeb.SpaceLive.Settings do
  use CyaneaWeb, :live_view

  alias Cyanea.Billing
  alias Cyanea.Spaces
  alias Cyanea.Spaces.Space
  alias CyaneaWeb.Components.OntologyPickerLive

  @impl true
  def mount(%{"username" => owner_name, "slug" => slug}, _session, socket) do
    space = Spaces.get_space_by_owner_and_slug(owner_name, slug)
    current_user = socket.assigns.current_user

    cond do
      is_nil(space) ->
        {:ok,
         socket
         |> put_flash(:error, "Space not found.")
         |> redirect(to: ~p"/explore")}

      not Spaces.owner?(space, current_user) ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have permission to manage this space.")
         |> redirect(to: ~p"/#{owner_name}/#{slug}")}

      true ->
        changeset = Space.changeset(space, %{})
        owner = load_owner(space)
        can_go_private = owner != nil && Billing.can_have_private_spaces?(owner)

        {:ok,
         assign(socket,
           page_title: "Settings — #{space.name}",
           space: space,
           owner_name: owner_name,
           form: to_form(changeset),
           can_go_private: can_go_private,
           ontology_terms: space.ontology_terms || []
         )}
    end
  end

  @impl true
  def handle_event("validate", %{"space" => params}, socket) do
    changeset =
      socket.assigns.space
      |> Space.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"space" => params}, socket) do
    case Spaces.update_space(socket.assigns.space, params) do
      {:ok, space} ->
        owner_name = socket.assigns.owner_name

        {:noreply,
         socket
         |> put_flash(:info, "Space updated successfully.")
         |> push_navigate(to: ~p"/#{owner_name}/#{space.slug}")}

      {:error, :pro_required} ->
        {:noreply,
         put_flash(socket, :error, "Private visibility requires a Pro plan. Upgrade to unlock private spaces.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("delete", _params, socket) do
    space = socket.assigns.space

    case Spaces.delete_space(space) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Space deleted.")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete space.")}
    end
  end

  @impl true
  def handle_info({OntologyPickerLive, :terms_updated, _id, terms}, socket) do
    space = socket.assigns.space

    case Spaces.update_space(space, %{ontology_terms: terms}) do
      {:ok, space} ->
        {:noreply, assign(socket, space: space, ontology_terms: terms)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update ontology terms.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header>
        Space settings
        <:subtitle><%= @owner_name %>/<%= @space.name %></:subtitle>
      </.header>

      <div class="mt-8 rounded-xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <.simple_form for={@form} phx-change="validate" phx-submit="save">
          <.input field={@form[:name]} type="text" label="Space name" required />
          <.input field={@form[:description]} type="textarea" label="Description" rows="3" />

          <.input
            field={@form[:visibility]}
            type="select"
            label="Visibility"
            options={[{"Public", "public"}, {"Private", "private"}]}
          />

          <p :if={!@can_go_private && @space.visibility != "private"} class="-mt-2 text-sm text-slate-500">
            Private visibility requires a Pro plan.
            <.link navigate={~p"/settings/billing"} class="font-medium text-primary hover:underline">
              Upgrade to Pro
            </.link>
          </p>

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

          <.input
            :if={@space.visibility == "public"}
            field={@form[:federation_policy]}
            type="select"
            label="Federation policy"
            options={[
              {"None — Not published to the network", "none"},
              {"Selective — Choose what to share", "selective"},
              {"Full — Share everything", "full"}
            ]}
          />
          <p :if={@space.visibility == "public"} class="-mt-2 text-sm text-slate-500">
            Controls whether this space is shared across the federated Cyanea network.
          </p>

          <:actions>
            <.link
              navigate={~p"/#{@owner_name}/#{@space.slug}"}
              class="text-sm font-medium text-slate-600 hover:text-slate-900 dark:text-slate-400"
            >
              Cancel
            </.link>
            <.button type="submit" phx-disable-with="Saving...">Save changes</.button>
          </:actions>
        </.simple_form>
      </div>

      <%!-- Ontology terms (separate section, saved independently via LiveComponent) --%>
      <div class="mt-8 rounded-xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <.live_component
          module={OntologyPickerLive}
          id="space-ontology-picker"
          selected_terms={@ontology_terms}
        />
      </div>

      <%!-- Danger zone --%>
      <div class="mt-8 rounded-xl border border-red-200 bg-white p-8 shadow-sm dark:border-red-900 dark:bg-slate-800">
        <h3 class="text-lg font-semibold text-red-600">Danger zone</h3>
        <p class="mt-2 text-sm text-slate-600 dark:text-slate-400">
          Deleting this space is permanent and cannot be undone. All notebooks, protocols,
          datasets, and files within this space will be removed.
        </p>
        <div class="mt-4">
          <button
            phx-click="delete"
            data-confirm={"Are you sure you want to delete #{@space.name}? This cannot be undone."}
            class="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
          >
            Delete this space
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp load_owner(%{owner_type: "user", owner_id: id}),
    do: Cyanea.Repo.get(Cyanea.Accounts.User, id)

  defp load_owner(%{owner_type: "organization", owner_id: id}),
    do: Cyanea.Repo.get(Cyanea.Organizations.Organization, id)

  defp load_owner(_), do: nil
end
