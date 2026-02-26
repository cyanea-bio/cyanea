defmodule CyaneaWeb.Router do
  use CyaneaWeb, :router

  import CyaneaWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CyaneaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Health checks (no auth, no session)
  scope "/", CyaneaWeb do
    pipe_through :api

    get "/health", HealthController, :live
    get "/ready", HealthController, :ready
  end

  # Session controller routes (must be outside LiveView scopes)
  scope "/auth", CyaneaWeb do
    pipe_through :browser

    post "/login", UserSessionController, :create
    delete "/logout", UserSessionController, :delete

    # ORCID OAuth
    get "/orcid", OAuthCallbackController, :request
    get "/orcid/callback", OAuthCallbackController, :callback
  end

  # Auth routes (redirect if already logged in)
  scope "/auth", CyaneaWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{CyaneaWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/login", AuthLive.Login, :new
      live "/register", AuthLive.Register, :new
    end
  end

  # Authenticated routes
  scope "/", CyaneaWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{CyaneaWeb.UserAuth, :ensure_authenticated}] do
      live "/new", SpaceLive.New, :new
      live "/settings", SettingsLive, :edit
      live "/dashboard", DashboardLive, :index

      # Organization management
      live "/organizations/new", OrganizationLive.New, :new
      live "/organizations/:slug/settings", OrganizationLive.Settings, :edit
      live "/organizations/:slug/members", OrganizationLive.Members, :index

      # Space settings (requires auth)
      live "/:username/:slug/settings", SpaceLive.Settings, :edit

      # Content creation (requires auth)
      live "/:username/:slug/notebooks/new", NotebookLive.New, :new
      live "/:username/:slug/protocols/new", ProtocolLive.New, :new
      live "/:username/:slug/datasets/new", DatasetLive.New, :new

      # Discussions (create requires auth)
      live "/:username/:slug/discussions/new", DiscussionLive.New, :new

      # Notifications
      live "/notifications", NotificationLive.Index, :index
    end
  end

  # Blob downloads (public scope, access checked in controller)
  scope "/", CyaneaWeb do
    pipe_through :browser

    get "/blobs/:id/download", BlobController, :download
  end

  # Public routes
  scope "/", CyaneaWeb do
    pipe_through :browser

    live_session :public,
      on_mount: [{CyaneaWeb.UserAuth, :mount_current_user}] do
      live "/", HomeLive, :index
      live "/explore", ExploreLive, :index
      live "/:username", UserLive.Show, :show
      live "/:username/:slug", SpaceLive.Show, :show

      # Discussions (public, access checked in mount)
      live "/:username/:slug/discussions", DiscussionLive.Index, :index
      live "/:username/:slug/discussions/:discussion_id", DiscussionLive.Show, :show

      # Content detail pages (public, access checked in mount)
      live "/:username/:slug/notebooks/:notebook_slug", NotebookLive.Show, :show
      live "/:username/:slug/protocols/:protocol_slug", ProtocolLive.Show, :show
      live "/:username/:slug/datasets/:dataset_slug", DatasetLive.Show, :show
    end
  end

  # Development routes
  if Application.compile_env(:cyanea, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CyaneaWeb.Telemetry
    end
  end
end
