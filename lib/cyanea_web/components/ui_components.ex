defmodule CyaneaWeb.UIComponents do
  @moduledoc """
  General-purpose display components for the Cyanea platform.

  These are visual atoms and small molecules — badges, avatars, cards, tabs,
  empty states, and other reusable UI building blocks.
  """
  use Phoenix.Component

  # ---------------------------------------------------------------------------
  # badge
  # ---------------------------------------------------------------------------

  @doc """
  Renders a colored badge/pill.

  ## Examples

      <.badge>Default</.badge>
      <.badge color={:primary}>Active</.badge>
      <.badge color={:success} size={:xs}>Passing</.badge>
  """
  attr :color, :atom,
    default: :gray,
    values: ~w(gray primary accent success warning error emerald amber violet rose)a

  attr :size, :atom, default: :sm, values: ~w(xs sm)a
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex items-center rounded-full font-medium",
        badge_size_class(@size),
        badge_color_class(@color),
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  defp badge_size_class(:xs), do: "px-1.5 py-0.5 text-[10px]"
  defp badge_size_class(:sm), do: "px-2 py-0.5 text-xs"

  defp badge_color_class(:gray),
    do: "bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300"

  defp badge_color_class(:primary),
    do: "bg-primary-100 text-primary-700 dark:bg-primary-900/30 dark:text-primary-400"

  defp badge_color_class(:accent),
    do: "bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400"

  defp badge_color_class(:success),
    do: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"

  defp badge_color_class(:warning),
    do: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"

  defp badge_color_class(:error),
    do: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400"

  defp badge_color_class(:emerald),
    do: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"

  defp badge_color_class(:amber),
    do: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"

  defp badge_color_class(:violet),
    do: "bg-violet-100 text-violet-700 dark:bg-violet-900/30 dark:text-violet-400"

  defp badge_color_class(:rose),
    do: "bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400"

  # ---------------------------------------------------------------------------
  # visibility_badge
  # ---------------------------------------------------------------------------

  @doc """
  Renders a visibility badge for artifacts/repositories.

  ## Examples

      <.visibility_badge visibility="public" />
      <.visibility_badge visibility="private" />
  """
  attr :visibility, :string, required: true, values: ~w(public private internal draft)

  def visibility_badge(%{visibility: "public"} = assigns) do
    ~H"""
    <.badge color={:emerald}>Public</.badge>
    """
  end

  def visibility_badge(%{visibility: "private"} = assigns) do
    ~H"""
    <.badge color={:amber}>Private</.badge>
    """
  end

  def visibility_badge(%{visibility: "internal"} = assigns) do
    ~H"""
    <.badge color={:primary}>Internal</.badge>
    """
  end

  def visibility_badge(%{visibility: "draft"} = assigns) do
    ~H"""
    <.badge color={:gray}>Draft</.badge>
    """
  end

  # ---------------------------------------------------------------------------
  # avatar
  # ---------------------------------------------------------------------------

  @doc """
  Renders a user or organization avatar with dicebear fallback.

  ## Examples

      <.avatar name="zara" />
      <.avatar name="Cyanea Labs" src="/images/logo.png" size={:lg} />
      <.avatar name="ACME Org" shape={:rounded} />
  """
  attr :src, :string, default: nil
  attr :name, :string, required: true
  attr :size, :atom, default: :md, values: ~w(xs sm md lg xl)a
  attr :shape, :atom, default: :circle, values: ~w(circle rounded)a
  attr :class, :string, default: nil
  attr :rest, :global

  def avatar(assigns) do
    assigns = assign(assigns, :resolved_src, resolve_avatar_src(assigns.src, assigns.name))

    ~H"""
    <img
      src={@resolved_src}
      alt={@name}
      class={[
        "object-cover",
        avatar_size_class(@size),
        avatar_shape_class(@shape),
        @class
      ]}
      {@rest}
    />
    """
  end

  defp resolve_avatar_src(nil, name),
    do: "https://api.dicebear.com/7.x/initials/svg?seed=#{URI.encode(name)}"

  defp resolve_avatar_src(src, _name), do: src

  defp avatar_size_class(:xs), do: "h-5 w-5"
  defp avatar_size_class(:sm), do: "h-8 w-8"
  defp avatar_size_class(:md), do: "h-10 w-10"
  defp avatar_size_class(:lg), do: "h-20 w-20"
  defp avatar_size_class(:xl), do: "h-48 w-48"

  defp avatar_shape_class(:circle), do: "rounded-full"
  defp avatar_shape_class(:rounded), do: "rounded-xl"

  # ---------------------------------------------------------------------------
  # card
  # ---------------------------------------------------------------------------

  @doc """
  Renders a card container with optional header and footer.

  ## Examples

      <.card>Content here</.card>
      <.card padding="p-0">
        <:header>Title</:header>
        Table content
        <:footer>Pagination</:footer>
      </.card>
  """
  attr :class, :string, default: nil
  attr :padding, :string, default: "p-6", values: ~w(p-0 p-4 p-6 p-8)
  attr :rest, :global

  slot :inner_block, required: true
  slot :header
  slot :footer

  def card(assigns) do
    ~H"""
    <div
      class={[
        "rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-800",
        @header == [] && @footer == [] && @padding,
        @class
      ]}
      {@rest}
    >
      <div
        :for={header <- @header}
        class="border-b border-slate-200 px-6 py-4 dark:border-slate-700"
      >
        <%= render_slot(header) %>
      </div>
      <div class={[(@header != [] || @footer != []) && @padding]}>
        <%= render_slot(@inner_block) %>
      </div>
      <div
        :for={footer <- @footer}
        class="border-t border-slate-200 px-6 py-4 dark:border-slate-700"
      >
        <%= render_slot(footer) %>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # tabs
  # ---------------------------------------------------------------------------

  @doc """
  Renders a tabbed navigation bar.

  ## Examples

      <.tabs>
        <:tab active={@tab == :all} patch={~p"/explore"}>All</:tab>
        <:tab active={@tab == :datasets} patch={~p"/explore?tab=datasets"} count={12}>
          Datasets
        </:tab>
      </.tabs>
  """
  attr :class, :string, default: nil

  slot :tab, required: true do
    attr :active, :boolean
    attr :patch, :string
    attr :click, :string
    attr :value, :string
    attr :count, :integer
  end

  def tabs(assigns) do
    ~H"""
    <div class={[
      "flex gap-1 border-b border-slate-200 dark:border-slate-700",
      @class
    ]}>
      <.tab_item :for={tab <- @tab} tab={tab} />
    </div>
    """
  end

  defp tab_item(%{tab: %{patch: patch}} = assigns) when is_binary(patch) do
    ~H"""
    <.link
      patch={@tab.patch}
      class={tab_classes(@tab[:active])}
    >
      <%= render_slot(@tab) %>
      <.tab_count :if={@tab[:count]} count={@tab[:count]} />
    </.link>
    """
  end

  defp tab_item(assigns) do
    ~H"""
    <button
      type="button"
      phx-click={@tab[:click]}
      phx-value-tab={@tab[:value]}
      class={tab_classes(@tab[:active])}
    >
      <%= render_slot(@tab) %>
      <.tab_count :if={@tab[:count]} count={@tab[:count]} />
    </button>
    """
  end

  defp tab_count(assigns) do
    ~H"""
    <span class="ml-1.5 rounded-full bg-slate-100 px-1.5 py-0.5 text-[10px] font-medium dark:bg-slate-700">
      <%= @count %>
    </span>
    """
  end

  defp tab_classes(true),
    do: "border-b-2 border-primary-500 px-4 py-2.5 text-sm font-medium text-primary"

  defp tab_classes(_),
    do:
      "border-b-2 border-transparent px-4 py-2.5 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"

  # ---------------------------------------------------------------------------
  # empty_state
  # ---------------------------------------------------------------------------

  @doc """
  Renders an empty state placeholder.

  ## Examples

      <.empty_state icon="hero-folder-plus" heading="No repositories">
        <:action>
          <.link navigate={~p"/new"}>Create one</.link>
        </:action>
      </.empty_state>
  """
  attr :icon, :string, default: nil
  attr :heading, :string, required: true
  attr :description, :string, default: nil
  attr :bordered, :boolean, default: false
  attr :class, :string, default: nil

  slot :action

  def empty_state(assigns) do
    ~H"""
    <div class={[
      "text-center",
      @bordered && "rounded-xl border-2 border-dashed border-slate-300 p-12 dark:border-slate-700",
      !@bordered && "py-8",
      @class
    ]}>
      <.icon
        :if={@icon}
        name={@icon}
        class="mx-auto h-12 w-12 text-slate-300 dark:text-slate-600"
      />
      <h3 class={["text-sm font-semibold text-slate-900 dark:text-white", @icon && "mt-2"]}>
        <%= @heading %>
      </h3>
      <p :if={@description} class="mt-1 text-sm text-slate-500 dark:text-slate-400">
        <%= @description %>
      </p>
      <div :if={@action != []} class="mt-4">
        <%= render_slot(@action) %>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # breadcrumb
  # ---------------------------------------------------------------------------

  @doc """
  Renders a breadcrumb trail.

  ## Examples

      <.breadcrumb>
        <:crumb navigate="/acme">ACME</:crumb>
        <:crumb navigate="/acme/repo">repo</:crumb>
        <:crumb>Files</:crumb>
      </.breadcrumb>
  """
  attr :class, :string, default: nil

  slot :crumb, required: true do
    attr :navigate, :string
    attr :href, :string
  end

  def breadcrumb(assigns) do
    assigns = assign(assigns, :last_index, length(assigns.crumb) - 1)

    ~H"""
    <nav class={["flex items-center gap-2 text-sm", @class]}>
      <%= for {crumb, idx} <- Enum.with_index(@crumb) do %>
        <span :if={idx > 0} class="text-slate-400">/</span>
        <%= if idx == @last_index do %>
          <span class="font-semibold text-slate-900 dark:text-white">
            <%= render_slot(crumb) %>
          </span>
        <% else %>
          <.link
            navigate={crumb[:navigate]}
            href={crumb[:href]}
            class="text-slate-500 hover:text-primary dark:text-slate-400 dark:hover:text-primary-400"
          >
            <%= render_slot(crumb) %>
          </.link>
        <% end %>
      <% end %>
    </nav>
    """
  end

  # ---------------------------------------------------------------------------
  # metadata_row
  # ---------------------------------------------------------------------------

  @doc """
  Renders an icon + text metadata row.

  ## Examples

      <.metadata_row icon="hero-clock">Updated 2h ago</.metadata_row>
      <.metadata_row icon="hero-scale">MIT License</.metadata_row>
  """
  attr :icon, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def metadata_row(assigns) do
    ~H"""
    <span class={["flex items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400", @class]} {@rest}>
      <.icon name={@icon} class="h-4 w-4 shrink-0" />
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  # ---------------------------------------------------------------------------
  # stat
  # ---------------------------------------------------------------------------

  @doc """
  Renders a stat display with value and label.

  ## Examples

      <.stat value={42} label="Repositories" />
      <.stat value="1.2K" label="Downloads" icon="hero-arrow-down-tray" />
  """
  attr :value, :any, required: true
  attr :label, :string, required: true
  attr :icon, :string, default: nil
  attr :class, :string, default: nil

  def stat(assigns) do
    ~H"""
    <div class={["text-center", @class]}>
      <div class="flex items-center justify-center gap-2">
        <.icon :if={@icon} name={@icon} class="h-5 w-5 text-slate-400" />
        <span class="text-2xl font-bold font-display tracking-tight text-slate-900 dark:text-white">
          <%= @value %>
        </span>
      </div>
      <span class="text-sm text-slate-500 dark:text-slate-400"><%= @label %></span>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # progress_bar
  # ---------------------------------------------------------------------------

  @doc """
  Renders a progress bar.

  ## Examples

      <.progress_bar value={75} />
      <.progress_bar value={100} color={:success} />
  """
  attr :value, :integer, default: 0
  attr :color, :atom, default: :primary, values: ~w(primary success warning error)a
  attr :size, :atom, default: :sm, values: ~w(xs sm md)a
  attr :class, :string, default: nil

  def progress_bar(assigns) do
    assigns = assign(assigns, :clamped, min(100, max(0, assigns.value)))

    ~H"""
    <div class={[
      "w-full rounded-full bg-slate-200 dark:bg-slate-700",
      progress_size_class(@size),
      @class
    ]}>
      <div
        class={["rounded-full transition-all duration-300", progress_color_class(@color), progress_size_class(@size)]}
        style={"width: #{@clamped}%"}
      />
    </div>
    """
  end

  defp progress_size_class(:xs), do: "h-1"
  defp progress_size_class(:sm), do: "h-1.5"
  defp progress_size_class(:md), do: "h-2.5"

  defp progress_color_class(:primary), do: "bg-primary"
  defp progress_color_class(:success), do: "bg-emerald-500"
  defp progress_color_class(:warning), do: "bg-amber-500"
  defp progress_color_class(:error), do: "bg-red-500"

  # ---------------------------------------------------------------------------
  # tooltip
  # ---------------------------------------------------------------------------

  @doc """
  Renders a tooltip on hover using pure CSS.

  ## Examples

      <.tooltip text="Copy to clipboard">
        <button>Copy</button>
      </.tooltip>
  """
  attr :text, :string, required: true
  attr :position, :atom, default: :top, values: ~w(top bottom left right)a

  slot :inner_block, required: true

  def tooltip(assigns) do
    ~H"""
    <span class="group relative inline-flex">
      <%= render_slot(@inner_block) %>
      <span class={[
        "pointer-events-none absolute hidden whitespace-nowrap rounded-md bg-slate-900 px-2 py-1 text-xs text-white shadow-lg group-hover:block z-50 dark:bg-slate-700",
        tooltip_position_class(@position)
      ]}>
        <%= @text %>
      </span>
    </span>
    """
  end

  defp tooltip_position_class(:top), do: "bottom-full left-1/2 -translate-x-1/2 mb-2"
  defp tooltip_position_class(:bottom), do: "top-full left-1/2 -translate-x-1/2 mt-2"
  defp tooltip_position_class(:left), do: "right-full top-1/2 -translate-y-1/2 mr-2"
  defp tooltip_position_class(:right), do: "left-full top-1/2 -translate-y-1/2 ml-2"

  # ---------------------------------------------------------------------------
  # kbd
  # ---------------------------------------------------------------------------

  @doc """
  Renders a keyboard shortcut indicator.

  ## Examples

      <.kbd>Ctrl</.kbd> + <.kbd>K</.kbd>
  """
  slot :inner_block, required: true
  attr :class, :string, default: nil

  def kbd(assigns) do
    ~H"""
    <kbd class={[
      "inline-flex items-center rounded bg-slate-200 px-1.5 py-0.5 text-xs font-medium text-slate-600 dark:bg-slate-700 dark:text-slate-300",
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </kbd>
    """
  end

  # ---------------------------------------------------------------------------
  # status_indicator
  # ---------------------------------------------------------------------------

  @doc """
  Renders a colored status dot with optional label.

  ## Examples

      <.status_indicator status={:online} />
      <.status_indicator status={:syncing} label="Syncing..." />
  """
  attr :status, :atom, required: true, values: ~w(online offline syncing pending error)a
  attr :label, :string, default: nil
  attr :class, :string, default: nil

  def status_indicator(assigns) do
    ~H"""
    <span class={["inline-flex items-center gap-1.5", @class]}>
      <span class={[
        "h-2 w-2 rounded-full",
        status_dot_class(@status)
      ]} />
      <span :if={@label} class="text-sm text-slate-600 dark:text-slate-400"><%= @label %></span>
    </span>
    """
  end

  defp status_dot_class(:online), do: "bg-emerald-500"
  defp status_dot_class(:offline), do: "bg-slate-400"
  defp status_dot_class(:syncing), do: "bg-amber-500 animate-pulse"
  defp status_dot_class(:pending), do: "bg-slate-400 animate-pulse"
  defp status_dot_class(:error), do: "bg-red-500"

  # ---------------------------------------------------------------------------
  # description_list
  # ---------------------------------------------------------------------------

  @doc """
  Renders a description list of term/value pairs.

  ## Examples

      <.description_list>
        <:item term="Name">Cyanea</:item>
        <:item term="Version">0.1.0</:item>
      </.description_list>
  """
  attr :class, :string, default: nil

  slot :item, required: true do
    attr :term, :string, required: true
  end

  def description_list(assigns) do
    ~H"""
    <dl class={["divide-y divide-slate-200 dark:divide-slate-700", @class]}>
      <div :for={item <- @item} class="flex justify-between gap-4 py-3">
        <dt class="text-sm font-medium text-slate-500 dark:text-slate-400"><%= item.term %></dt>
        <dd class="text-sm text-slate-900 dark:text-white"><%= render_slot(item) %></dd>
      </div>
    </dl>
    """
  end

  # ---------------------------------------------------------------------------
  # Delegated icon (from CoreComponents to avoid import conflicts)
  # ---------------------------------------------------------------------------

  defp icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end
end
