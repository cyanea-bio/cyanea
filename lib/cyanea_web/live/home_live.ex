defmodule CyaneaWeb.HomeLive do
  @moduledoc """
  Home page LiveView.
  """
  use CyaneaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns[:current_user] do
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    else
      {:ok, assign(socket, page_title: "Home")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-[60vh] flex-col items-center justify-center text-center">
      <div class="mb-8">
        <img src={~p"/images/mascot.png"} alt="Cyanea mascot" class="mx-auto h-24 w-24 drop-shadow-lg" />
      </div>

      <h1 class="text-4xl font-bold tracking-tight text-slate-900 sm:text-5xl dark:text-white">
        GitHub for Life Sciences
      </h1>

      <p class="mx-auto mt-6 max-w-2xl text-lg leading-8 text-slate-600 dark:text-slate-400">
        Store datasets, protocols, experiments, and analyses. Version control everything.
        Collaborate within orgs or publish openly. Own your data.
      </p>

      <div class="mt-10 flex items-center justify-center gap-4">
        <.link
          navigate={~p"/auth/register"}
          class="rounded-xl bg-primary px-6 py-3 text-base font-semibold text-white shadow-sm transition hover:bg-primary-700"
        >
          Get started
        </.link>
        <.link
          navigate={~p"/explore"}
          class="rounded-xl border border-slate-300 bg-white px-6 py-3 text-base font-semibold text-slate-900 shadow-sm transition hover:bg-slate-50 dark:border-slate-600 dark:bg-slate-800 dark:text-white dark:hover:bg-slate-700"
        >
          Explore
        </.link>
      </div>

      <div class="mt-16 grid gap-8 sm:grid-cols-3">
        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:shadow-md dark:border-slate-700 dark:bg-slate-800">
          <div class="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-primary-100 text-primary dark:bg-primary-900/50">
            <.icon name="hero-document-text" class="h-6 w-6" />
          </div>
          <h3 class="text-lg font-semibold text-slate-900 dark:text-white">Protocols</h3>
          <p class="mt-2 text-sm text-slate-600 dark:text-slate-400">
            Structured protocols with materials, steps, and timings. Version and fork.
          </p>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:shadow-md dark:border-slate-700 dark:bg-slate-800">
          <div class="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-primary-100 text-primary dark:bg-primary-900/50">
            <.icon name="hero-circle-stack" class="h-6 w-6" />
          </div>
          <h3 class="text-lg font-semibold text-slate-900 dark:text-white">Datasets</h3>
          <p class="mt-2 text-sm text-slate-600 dark:text-slate-400">
            CSV, FASTA, images, notebooks. Preview inline. Track provenance.
          </p>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:shadow-md dark:border-slate-700 dark:bg-slate-800">
          <div class="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-primary-100 text-primary dark:bg-primary-900/50">
            <.icon name="hero-users" class="h-6 w-6" />
          </div>
          <h3 class="text-lg font-semibold text-slate-900 dark:text-white">Collaborate</h3>
          <p class="mt-2 text-sm text-slate-600 dark:text-slate-400">
            Organizations, teams, and access control. Public or private.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
