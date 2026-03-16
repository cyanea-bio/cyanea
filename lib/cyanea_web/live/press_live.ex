defmodule CyaneaWeb.PressLive do
  @moduledoc """
  Press kit page — brand assets, company description, and contact information.
  """
  use CyaneaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Press Kit")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl">
      <%!-- Header --%>
      <section class="pb-12 pt-8">
        <h1 class="text-4xl font-bold tracking-tight text-slate-900 sm:text-5xl dark:text-white">
          Press Kit
        </h1>
        <p class="mt-4 max-w-2xl text-lg text-slate-600 dark:text-slate-400">
          Everything you need to write about Cyanea. Brand assets, company description, and contact information.
        </p>
      </section>

      <%!-- About --%>
      <section class="border-t border-slate-200 py-12 dark:border-slate-700">
        <h2 class="text-2xl font-semibold text-slate-900 dark:text-white">About Cyanea</h2>
        <div class="mt-6 max-w-2xl">
          <p class="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
            One-liner
          </p>
          <p class="mt-2 text-lg font-medium text-slate-900 dark:text-white">
            Cyanea is a federated, community-first platform for life science R&D — what GitHub did for code, applied to bioinformatics, protocols, and experimental data.
          </p>
          <button
            phx-click={JS.dispatch("phx:copy", detail: %{text: "Cyanea is a federated, community-first platform for life science R&D — what GitHub did for code, applied to bioinformatics, protocols, and experimental data."})}
            class="mt-2 inline-flex items-center gap-1.5 rounded-full border border-slate-200 px-3 py-1 text-xs text-slate-500 transition hover:border-slate-400 hover:text-slate-700 dark:border-slate-700 dark:hover:border-slate-500 dark:hover:text-slate-300"
          >
            <.icon name="hero-clipboard-document" class="h-3.5 w-3.5" /> Copy
          </button>

          <p class="mt-8 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
            Short description
          </p>
          <p class="mt-2 leading-7 text-slate-600 dark:text-slate-400">
            Cyanea lets researchers store, version, and share datasets, protocols, notebooks, and analyses. Organizations can self-host a node for private work and selectively publish to the federated network. Built on a world-class Rust bioinformatics engine (Cyanea Labs) with both browser-side WASM and server-side compute, it brings modern developer tooling — forking, lineage tracking, reproducibility — to the life sciences.
          </p>
          <button
            phx-click={JS.dispatch("phx:copy", detail: %{text: "Cyanea lets researchers store, version, and share datasets, protocols, notebooks, and analyses. Organizations can self-host a node for private work and selectively publish to the federated network. Built on a world-class Rust bioinformatics engine (Cyanea Labs) with both browser-side WASM and server-side compute, it brings modern developer tooling — forking, lineage tracking, reproducibility — to the life sciences."})}
            class="mt-2 inline-flex items-center gap-1.5 rounded-full border border-slate-200 px-3 py-1 text-xs text-slate-500 transition hover:border-slate-400 hover:text-slate-700 dark:border-slate-700 dark:hover:border-slate-500 dark:hover:text-slate-300"
          >
            <.icon name="hero-clipboard-document" class="h-3.5 w-3.5" /> Copy
          </button>

          <p class="mt-8 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
            Extended description
          </p>
          <p class="mt-2 leading-7 text-slate-600 dark:text-slate-400">
            Cyanea is a federated R&D platform where labs and researchers manage their scientific artifacts — datasets, protocols, notebooks, and analyses — with the same version control, collaboration, and discovery tools that transformed software engineering. Each organization runs its own node with full data sovereignty, publishing selected work to the open network for community reuse and citation. Underneath the platform sits Cyanea Labs, a from-scratch Rust bioinformatics ecosystem of 15 crates covering sequence analysis, alignment, omics, statistics, machine learning, chemistry, structural biology, phylogenetics, and more — all compiled to both native and WebAssembly for instant browser-based computation. The platform is open source, built with Elixir and Phoenix LiveView, and designed around trust: immutable versioning, content-addressed storage, provenance tracking, and reproducible pipelines are first-class features, not afterthoughts.
          </p>
          <button
            phx-click={JS.dispatch("phx:copy", detail: %{text: "Cyanea is a federated R&D platform where labs and researchers manage their scientific artifacts — datasets, protocols, notebooks, and analyses — with the same version control, collaboration, and discovery tools that transformed software engineering. Each organization runs its own node with full data sovereignty, publishing selected work to the open network for community reuse and citation. Underneath the platform sits Cyanea Labs, a from-scratch Rust bioinformatics ecosystem of 15 crates covering sequence analysis, alignment, omics, statistics, machine learning, chemistry, structural biology, phylogenetics, and more — all compiled to both native and WebAssembly for instant browser-based computation. The platform is open source, built with Elixir and Phoenix LiveView, and designed around trust: immutable versioning, content-addressed storage, provenance tracking, and reproducible pipelines are first-class features, not afterthoughts."})}
            class="mt-2 inline-flex items-center gap-1.5 rounded-full border border-slate-200 px-3 py-1 text-xs text-slate-500 transition hover:border-slate-400 hover:text-slate-700 dark:border-slate-700 dark:hover:border-slate-500 dark:hover:text-slate-300"
          >
            <.icon name="hero-clipboard-document" class="h-3.5 w-3.5" /> Copy
          </button>
        </div>
      </section>

      <%!-- Quick Facts --%>
      <section class="border-t border-slate-200 py-12 dark:border-slate-700">
        <h2 class="text-2xl font-semibold text-slate-900 dark:text-white">Quick facts</h2>
        <div class="mt-6 max-w-2xl">
          <.fact_row label="Full name" value="Cyanea" />
          <.fact_row label="Pronunciation" value="sai·AH·nee·uh (from Greek kyanos, dark blue)" />
          <.fact_row label="Named after" value="Cyanea capillata — the lion's mane jellyfish" />
          <.fact_row label="Founded" value="2025" />
          <.fact_row label="Category" value="Life science R&D platform, bioinformatics" />
          <.fact_row label="License" value="Open source" />
          <.fact_row label="Website">
            <a href="https://cyanea.bio" class="text-primary hover:underline">cyanea.bio</a>
          </.fact_row>
          <.fact_row label="GitHub">
            <a href="https://github.com/cyanea-bio" class="text-primary hover:underline">github.com/cyanea-bio</a>
          </.fact_row>
        </div>
      </section>

      <%!-- Brand Name Usage --%>
      <section class="border-t border-slate-200 py-12 dark:border-slate-700">
        <h2 class="text-2xl font-semibold text-slate-900 dark:text-white">Brand name</h2>
        <div class="mt-6 grid max-w-2xl gap-6 sm:grid-cols-2">
          <div class="rounded-xl border border-slate-200 p-5 dark:border-slate-700">
            <p class="text-xs font-semibold uppercase tracking-wider text-green-600 dark:text-green-400">Use</p>
            <ul class="mt-3 space-y-1 text-sm text-slate-600 dark:text-slate-400">
              <li>Cyanea (preferred)</li>
              <li>cyanea (lowercase, also correct)</li>
              <li>Cyanea Labs (for the Rust ecosystem)</li>
            </ul>
          </div>
          <div class="rounded-xl border border-slate-200 p-5 dark:border-slate-700">
            <p class="text-xs font-semibold uppercase tracking-wider text-red-600 dark:text-red-400">Don't use</p>
            <ul class="mt-3 space-y-1 text-sm text-slate-600 dark:text-slate-400">
              <li>CYANEA</li>
              <li>CyaneA</li>
              <li>Cyanea.bio (the domain is not the name)</li>
              <li>Cyanea.io</li>
            </ul>
          </div>
        </div>
      </section>

      <%!-- Logo & Assets --%>
      <section class="border-t border-slate-200 py-12 dark:border-slate-700">
        <h2 class="text-2xl font-semibold text-slate-900 dark:text-white">Logo and assets</h2>

        <p class="mt-8 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
          Brandmark
        </p>
        <div class="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <div class="overflow-hidden rounded-xl border border-slate-200 transition hover:border-slate-400 dark:border-slate-700 dark:hover:border-slate-500">
            <div class="flex min-h-[140px] items-center justify-center bg-slate-900 p-8">
              <img src={~p"/images/icon.png"} alt="Cyanea icon on dark background" class="h-20 w-20" />
            </div>
            <div class="flex items-center justify-between border-t border-slate-200 px-4 py-3 dark:border-slate-700">
              <div>
                <p class="text-sm font-medium text-slate-900 dark:text-white">Brandmark</p>
                <p class="text-xs text-slate-500">PNG, dark background</p>
              </div>
              <a href={~p"/images/icon.png"} download class="text-xs font-medium text-primary hover:underline">
                Download
              </a>
            </div>
          </div>
          <div class="overflow-hidden rounded-xl border border-slate-200 transition hover:border-slate-400 dark:border-slate-700 dark:hover:border-slate-500">
            <div class="flex min-h-[140px] items-center justify-center bg-white p-8">
              <img src={~p"/images/icon.png"} alt="Cyanea icon on light background" class="h-20 w-20" />
            </div>
            <div class="flex items-center justify-between border-t border-slate-200 px-4 py-3 dark:border-slate-700">
              <div>
                <p class="text-sm font-medium text-slate-900 dark:text-white">Brandmark</p>
                <p class="text-xs text-slate-500">PNG, light background</p>
              </div>
              <a href={~p"/images/icon.png"} download class="text-xs font-medium text-primary hover:underline">
                Download
              </a>
            </div>
          </div>
        </div>

        <p class="mt-8 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
          Mascot
        </p>
        <div class="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <div class="overflow-hidden rounded-xl border border-slate-200 transition hover:border-slate-400 dark:border-slate-700 dark:hover:border-slate-500">
            <div class="flex min-h-[140px] items-center justify-center bg-slate-50 p-8 dark:bg-slate-800">
              <img src={~p"/images/mascot.png"} alt="Cyanea jellyfish mascot" class="h-20 w-20" />
            </div>
            <div class="flex items-center justify-between border-t border-slate-200 px-4 py-3 dark:border-slate-700">
              <div>
                <p class="text-sm font-medium text-slate-900 dark:text-white">Mascot</p>
                <p class="text-xs text-slate-500">PNG</p>
              </div>
              <a href={~p"/images/mascot.png"} download class="text-xs font-medium text-primary hover:underline">
                Download
              </a>
            </div>
          </div>
        </div>
      </section>

      <%!-- Colors --%>
      <section class="border-t border-slate-200 py-12 dark:border-slate-700">
        <h2 class="text-2xl font-semibold text-slate-900 dark:text-white">Colors</h2>

        <p class="mt-8 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
          Primary palette
        </p>
        <div class="mt-4 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          <.color_card name="Primary (Cyan)" hex="#06B6D4" />
          <.color_card name="Primary dark" hex="#0e7490" />
          <.color_card name="Accent (Violet)" hex="#8B5CF6" />
          <.color_card name="Rose" hex="#f43f5e" />
        </div>

        <p class="mt-8 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
          Semantic
        </p>
        <div class="mt-4 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          <.color_card name="Success" hex="#22C55E" />
          <.color_card name="Warning" hex="#F59E0B" />
          <.color_card name="Error" hex="#EF4444" />
        </div>

        <p class="mt-8 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
          Backgrounds
        </p>
        <div class="mt-4 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          <.color_card name="Dark background" hex="#0B1120" />
          <.color_card name="Dark surface" hex="#1e293b" />
          <.color_card name="Light background" hex="#ffffff" />
          <.color_card name="Light surface" hex="#f8fafc" />
        </div>
      </section>

      <%!-- Typography --%>
      <section class="border-t border-slate-200 py-12 dark:border-slate-700">
        <h2 class="text-2xl font-semibold text-slate-900 dark:text-white">Typography</h2>
        <div class="mt-6 max-w-2xl divide-y divide-slate-200 dark:divide-slate-700">
          <div class="py-5">
            <p class="text-xs uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Headings: Epilogue
            </p>
            <p class="mt-2 font-display text-3xl font-light tracking-tight text-slate-900 dark:text-white">
              GitHub for Life Sciences
            </p>
          </div>
          <div class="py-5">
            <p class="text-xs uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Body: Inter
            </p>
            <p class="mt-2 text-base leading-7 text-slate-600 dark:text-slate-400">
              Store datasets, protocols, experiments, and analyses. Version control everything. Collaborate within orgs or publish openly. Own your data.
            </p>
          </div>
          <div class="py-5">
            <p class="text-xs uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Code: JetBrains Mono
            </p>
            <p class="mt-2 font-mono text-sm leading-7 text-slate-600 dark:text-slate-400">
              let seq = Seq.from_fasta("genome.fa") |> Seq.reverse_complement()
            </p>
          </div>
        </div>
      </section>

      <%!-- Contact --%>
      <section class="border-t border-slate-200 py-12 dark:border-slate-700">
        <h2 class="text-2xl font-semibold text-slate-900 dark:text-white">Contact</h2>
        <div class="mt-4 max-w-2xl leading-7 text-slate-600 dark:text-slate-400">
          <p>
            For press inquiries, interviews, or assets in other formats:
            <a href="mailto:press@cyanea.bio" class="text-primary hover:underline">press@cyanea.bio</a>
          </p>
          <p class="mt-2">
            For general questions about the platform:
            <a href="mailto:hello@cyanea.bio" class="text-primary hover:underline">hello@cyanea.bio</a>
          </p>
        </div>
      </section>
    </div>
    """
  end

  defp fact_row(%{value: _} = assigns) do
    ~H"""
    <div class="grid grid-cols-[10rem_1fr] gap-4 border-b border-slate-200 py-3 text-sm dark:border-slate-700 max-sm:grid-cols-1 max-sm:gap-1">
      <span class="text-slate-500 dark:text-slate-400"><%= @label %></span>
      <span class="text-slate-900 dark:text-white"><%= @value %></span>
    </div>
    """
  end

  defp fact_row(assigns) do
    ~H"""
    <div class="grid grid-cols-[10rem_1fr] gap-4 border-b border-slate-200 py-3 text-sm dark:border-slate-700 max-sm:grid-cols-1 max-sm:gap-1">
      <span class="text-slate-500 dark:text-slate-400"><%= @label %></span>
      <span class="text-slate-900 dark:text-white"><%= render_slot(@inner_block) %></span>
    </div>
    """
  end

  defp color_card(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-xl border border-slate-200 dark:border-slate-700">
      <div class="h-20" style={"background: #{@hex};"}></div>
      <div class="px-4 py-3">
        <p class="text-sm font-medium text-slate-900 dark:text-white"><%= @name %></p>
        <p class="font-mono text-xs text-slate-500"><%= @hex %></p>
      </div>
    </div>
    """
  end
end
