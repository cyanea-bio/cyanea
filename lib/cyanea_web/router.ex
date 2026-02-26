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

  # Stripe webhooks (API pipeline, no CSRF)
  scope "/webhooks", CyaneaWeb do
    pipe_through :api

    post "/stripe", StripeWebhookController, :create
  end

  # Federation API (node-to-node communication)
  scope "/api/federation", CyaneaWeb do
    pipe_through :api

    get "/health", FederationController, :health
    get "/manifests", FederationController, :list_manifests
    get "/manifests/:global_id", FederationController, :show_manifest
    get "/revisions/:space_id", FederationController, :list_revisions
    get "/blobs/:space_id", FederationController, :list_blob_hashes
    post "/sync/push", FederationController, :receive_push
    post "/register", FederationController, :register_remote
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

      # Billing
      live "/settings/billing", BillingLive, :index
      live "/organizations/:slug/settings/billing", OrganizationBillingLive, :index

      # Federation admin
      live "/federation", FederationLive.Dashboard, :index
      live "/federation/nodes/:id", FederationLive.NodeShow, :show

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

      # File previews (public, access checked in mount)
      live "/:username/:slug/files/:file_id", FilePreviewLive, :show

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
