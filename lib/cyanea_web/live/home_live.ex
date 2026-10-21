defmodule CyaneaWeb.HomeLive do
  @moduledoc """
  Home page LiveView: the landing page for signed-out visitors.
  Signed-in users go straight to their dashboard.
  """
  use CyaneaWeb, :live_view

  @steps [
    {"01 · Re-run", "One click, same answer", "hero-arrow-path",
     "Notebooks execute in the browser or on server compute with pinned inputs, so a result from last year still reproduces.",
     "text-accent-700 dark:text-glow-cyan"},
    {"02 · Trace", "Every number has a lineage", "hero-share",
     "Follow any figure back through cells, code versions and datasets to the raw files it came from.",
     "text-primary-600 dark:text-glow-lavender"},
    {"03 · Review", "Diff analyses like code", "hero-code-bracket",
     "Cell-level diffs between versions, so a changed parameter is visible before it reaches a paper.",
     "text-rose-700 dark:text-glow-pink"},
    {"04 · Federate", "Run where the data lives", "hero-globe-europe-africa",
     "Self-host an instance next to sensitive data and share the method, not the files.",
     "text-lime-700 dark:text-glow-lime"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns[:current_user] do
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    else
      {:ok, assign(socket, page_title: "Home", full_bleed: true, steps: @steps)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- Full-width deep-sea band, one per page, dark in both themes --%>
    <section class="relative left-1/2 isolate w-screen -translate-x-1/2 overflow-hidden bg-abyss text-abyss-foam">
      <canvas id="hero-field" phx-hook="HeroField" phx-update="ignore" class="absolute inset-0 -z-10 h-full w-full" aria-hidden="true"></canvas>
      <div aria-hidden="true" class="absolute inset-0 -z-20 bg-[radial-gradient(120%_90%_at_75%_110%,rgba(91,63,217,0.22),transparent_60%)]"></div>

      <div class="mx-auto flex max-w-7xl flex-col items-start gap-6 px-4 py-20 sm:px-6 lg:px-8 lg:py-28">
        <a href="https://cyanea.bio/status" class="inline-flex items-center gap-2.5 rounded-full border border-abyss-line bg-abyss-2/70 py-1 pl-1 pr-3.5 text-sm text-abyss-body transition hover:border-primary-500 hover:text-abyss-foam">
          <span class="rounded-full bg-lime-400 px-2.5 py-0.5 text-xs font-bold text-abyss">Public alpha</span>
          Open source and self-hostable
          <.icon name="hero-arrow-right-mini" class="h-4 w-4" />
        </a>

        <h1 class="max-w-3xl font-display text-[clamp(2.6rem,6.4vw,4.75rem)] font-extrabold leading-[0.98] tracking-[-0.05em] text-abyss-foam">
          The system of record for
          <span class="bg-[linear-gradient(90deg,#8BEBFF,#C3B3FF_50%,#FFB3DA)] bg-clip-text text-transparent">computational biology.</span>
        </h1>

        <p class="max-w-xl text-lg leading-relaxed text-abyss-body">
          Notebooks, datasets and protocols that stay versioned, provenance-tracked and re-runnable. Open one, press run, get the same answer.
        </p>

        <div class="flex w-full flex-col gap-3 sm:w-auto sm:flex-row">
          <.link
            navigate={~p"/auth/register"}
            class="rounded-[14px] bg-glow-cyan px-6 py-3.5 text-center text-base font-bold text-abyss shadow-[0_0_30px_rgba(139,235,255,0.28)] transition hover:bg-[#B5F3FF] hover:shadow-[0_0_40px_rgba(139,235,255,0.45)]"
          >
            Start a notebook
          </.link>
          <.link
            navigate={~p"/explore"}
            class="rounded-[14px] border border-[#6F5FC4] bg-[rgba(185,166,255,0.12)] px-6 py-3.5 text-center text-base font-semibold text-abyss-foam transition hover:border-glow-lavender hover:bg-[rgba(185,166,255,0.22)]"
          >
            Explore the commons
          </.link>
        </div>
      </div>
      <div aria-hidden="true" class="absolute inset-x-0 bottom-0 h-[3px] bg-[linear-gradient(90deg,#8BE4F5,#B9A6FF_38%,#FFA6D2_70%,#D6F98F)]"></div>
    </section>

    <section class="py-16">
      <p class="mb-2 font-mono text-xs uppercase tracking-[0.08em] text-accent-700 dark:text-glow-cyan">How it works</p>
      <h2 class="mb-8 font-display text-3xl font-bold tracking-[-0.035em] text-slate-950 dark:text-white sm:text-4xl">
        Results that stay true
      </h2>
      <ol class="grid gap-px overflow-hidden rounded-[20px] border border-slate-200 bg-slate-200 dark:border-slate-800 dark:bg-slate-800 sm:grid-cols-2 lg:grid-cols-4">
        <li :for={{num, title, icon, text, colour} <- @steps} class="flex flex-col gap-2.5 bg-white p-6 dark:bg-slate-950">
          <span class={["inline-flex items-center gap-2 font-mono text-xs uppercase tracking-[0.06em]", colour]}>
            <.icon name={icon} class="h-4 w-4" /> <%= num %>
          </span>
          <h3 class="font-display text-xl font-bold tracking-[-0.02em] text-slate-950 dark:text-white"><%= title %></h3>
          <p class="text-[0.9375rem] leading-relaxed text-slate-600 dark:text-slate-400"><%= text %></p>
        </li>
      </ol>
    </section>

    <section class="mb-4 grid items-center gap-8 rounded-[24px] border border-primary-200 bg-primary-50 p-8 shadow-[0_4px_0_theme(colors.primary.200)] dark:border-primary-900 dark:bg-primary-950/40 dark:shadow-[0_4px_0_theme(colors.primary.900)] lg:grid-cols-[1fr_auto] lg:p-10">
      <div>
        <p class="mb-2 font-mono text-xs uppercase tracking-[0.08em] text-primary-600 dark:text-glow-lavender">Learn</p>
        <h2 class="font-display text-3xl font-bold tracking-[-0.035em] text-slate-950 dark:text-white">
          Learn biology by
          <span class="bg-[linear-gradient(90deg,#0B9CC4,#5B3FD9_55%,#D63F8C)] bg-clip-text text-transparent dark:bg-[linear-gradient(90deg,#8BEBFF,#C3B3FF_50%,#FFB3DA)]">running it.</span>
        </h2>
        <p class="mt-3 max-w-xl leading-relaxed text-slate-600 dark:text-slate-400">
          Lessons from the cell to the genome, each with code you can run and a simulation you can break. No install needed.
        </p>
      </div>
      <a href="https://cyanea.bio/learn" class="inline-flex items-center justify-center gap-2 rounded-xl bg-primary px-5 py-3 font-semibold text-white transition hover:bg-primary-700 dark:bg-primary-400 dark:text-abyss dark:hover:bg-primary-300">
        Start learning <.icon name="hero-arrow-right-mini" class="h-4 w-4" />
      </a>
    </section>
    """
  end
end
