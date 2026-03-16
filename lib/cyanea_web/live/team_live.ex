defmodule CyaneaWeb.TeamLive do
  @moduledoc """
  Team page — meet the people behind Cyanea.
  """
  use CyaneaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Team")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl">
      <div class="grid gap-12 lg:grid-cols-[200px_1fr]">
        <%!-- Left: Table of Contents --%>
        <aside class="lg:sticky lg:top-24 lg:self-start">
          <h2 class="text-xs font-semibold uppercase tracking-widest text-slate-400 dark:text-slate-500">
            Team
          </h2>
          <nav class="mt-4">
            <ul class="space-y-1">
              <li>
                <a
                  href="#raffael-schneider"
                  class="block border-l-2 border-primary px-3 py-1 text-sm font-medium text-primary"
                >
                  Raffael Schneider
                </a>
              </li>
            </ul>
            <hr class="my-4 border-slate-200 dark:border-slate-700" />
            <p class="text-xs uppercase tracking-wider text-slate-400 dark:text-slate-500">Company</p>
            <ul class="mt-2 space-y-1">
              <li>
                <.link
                  navigate={~p"/explore"}
                  class="block border-l-2 border-transparent px-3 py-1 text-sm text-slate-500 transition hover:border-primary hover:text-primary dark:text-slate-400"
                >
                  Explore
                </.link>
              </li>
              <li>
                <.link
                  navigate={~p"/press"}
                  class="block border-l-2 border-transparent px-3 py-1 text-sm text-slate-500 transition hover:border-primary hover:text-primary dark:text-slate-400"
                >
                  Press
                </.link>
              </li>
            </ul>
          </nav>
        </aside>

        <%!-- Right: Team members --%>
        <div class="min-w-0">
          <article id="raffael-schneider" class="scroll-mt-24">
            <div class="flex items-center gap-6 max-sm:flex-col max-sm:items-start">
              <div class="h-[7.5rem] w-[7.5rem] flex-shrink-0 overflow-hidden rounded-full border border-slate-200 bg-slate-100 dark:border-slate-700 dark:bg-slate-800">
                <img
                  src="https://avatars.githubusercontent.com/u/3826719"
                  alt="Portrait of Raffael Schneider"
                  class="h-full w-full object-cover"
                  loading="lazy"
                />
              </div>
              <div>
                <h1 class="text-3xl font-light tracking-tight text-slate-900 dark:text-white">
                  Raffael Schneider
                </h1>
                <p class="mt-1 font-medium text-primary">Founder</p>
              </div>
            </div>

            <div class="mt-6 flex flex-wrap items-center gap-5">
              <a
                href="https://www.linkedin.com/in/raffael-e-schneider"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-2 text-sm text-slate-500 transition hover:text-primary dark:text-slate-400"
              >
                <svg viewBox="0 0 24 24" fill="currentColor" class="h-4 w-4" aria-hidden="true">
                  <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 01-2.063-2.065 2.064 2.064 0 112.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
                </svg>
                LinkedIn
              </a>
              <span class="text-slate-300 dark:text-slate-600" aria-hidden="true">/</span>
              <a
                href="https://raskell.io"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-2 text-sm text-slate-500 transition hover:text-primary dark:text-slate-400"
              >
                <.icon name="hero-pencil-square" class="h-4 w-4" />
                raskell.io
              </a>
              <span class="text-slate-300 dark:text-slate-600" aria-hidden="true">/</span>
              <a
                href="https://github.com/raffaelschneider"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-2 text-sm text-slate-500 transition hover:text-primary dark:text-slate-400"
              >
                <svg viewBox="0 0 24 24" fill="currentColor" class="h-4 w-4" aria-hidden="true">
                  <path d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
                </svg>
                GitHub
              </a>
            </div>

            <div class="mt-8 space-y-4 leading-7 text-slate-600 dark:text-slate-400">
              <p>
                Platform engineer and security-focused technologist based in Switzerland. Raffael builds across platform automation, edge infrastructure, applied security, and open standards. He speaks at conferences and consults on infrastructure and systems engineering.
              </p>
              <p>
                The idea behind Cyanea grew from a conviction that life science research deserves the same tooling that transformed software development. Researchers shouldn't be emailing spreadsheets, losing track of protocol versions, or struggling to reproduce analyses from a paper published two years ago. The tools exist for code — version control, forking, collaboration, continuous integration — but bioinformatics and wet-lab science have been left behind.
              </p>
              <p>
                Cyanea is the result: a federated platform built on a Rust bioinformatics engine that compiles to both native and WebAssembly, an Elixir/Phoenix backend designed for real-time collaboration and fault tolerance, and a community model that respects data sovereignty while enabling open science. The technical choices are deliberate — Rust for performance and safety, Elixir for concurrency and distribution, federation for institutional autonomy.
              </p>
              <p>
                The conviction is straightforward: trusted, versioned, attributable scientific artifacts — not proprietary notebooks — are the moat in a post-AI world. Cyanea is building that foundation.
              </p>
            </div>
          </article>

          <div class="mt-12 border-t border-slate-200 pt-8 text-sm text-slate-400 dark:border-slate-700 dark:text-slate-500">
            Interested in joining the mission?
            <a href="mailto:hello@cyanea.bio" class="text-primary hover:underline">Get in touch</a>.
          </div>
        </div>
      </div>
    </div>
    """
  end
end
