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

  pipeline :api_v1 do
    plug :accepts, ["json"]
    plug CyaneaWeb.Plugs.Cors
    plug CyaneaWeb.Plugs.ApiAuth
    plug CyaneaWeb.Plugs.RateLimit
  end

  # Health checks (no auth, no session)
  scope "/", CyaneaWeb do
    pipe_through :api

    get "/health", HealthController, :live
    get "/ready", HealthController, :ready
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

  # REST API v1 — public endpoints (reads + JWT issuance)
  scope "/api/v1", CyaneaWeb.Api.V1 do
    pipe_through :api_v1

    post "/auth/token", AuthController, :create_jwt

    get "/spaces", SpaceController, :index
    get "/spaces/:id", SpaceController, :show

    get "/spaces/:space_id/notebooks", NotebookController, :index
    get "/spaces/:space_id/notebooks/:id", NotebookController, :show

    get "/spaces/:space_id/protocols", ProtocolController, :index
    get "/spaces/:space_id/protocols/:id", ProtocolController, :show

    get "/spaces/:space_id/datasets", DatasetController, :index
    get "/spaces/:space_id/datasets/:id", DatasetController, :show
    get "/spaces/:space_id/datasets/:dataset_id/files", DatasetController, :list_files

    get "/users/:username", UserController, :show
    get "/users/:username/spaces", UserController, :spaces

    get "/orgs/:slug", OrganizationController, :show
    get "/orgs/:slug/spaces", OrganizationController, :spaces
    get "/orgs/:slug/members", OrganizationController, :members

    get "/search", SearchController, :search

    # Learn — public endpoints
    get "/learn/tracks", LearnController, :list_tracks
    get "/learn/tracks/:slug", LearnController, :show_track
    get "/learn/paths/:id", LearnController, :show_path
  end

  # REST API v1 — authenticated endpoints (writes + management)
  scope "/api/v1", CyaneaWeb.Api.V1 do
    pipe_through [:api_v1, CyaneaWeb.Plugs.RequireApiAuth]

    get "/user", UserController, :me

    # API key management
    post "/auth/tokens", AuthController, :create_api_key
    get "/auth/tokens", AuthController, :list_api_keys
    delete "/auth/tokens/:id", AuthController, :revoke_api_key

    # Space CRUD
    post "/spaces", SpaceController, :create
    patch "/spaces/:id", SpaceController, :update
    delete "/spaces/:id", SpaceController, :delete
    post "/spaces/:id/fork", SpaceController, :fork

    # Notebook CRUD + import
    post "/spaces/:space_id/notebooks", NotebookController, :create
    patch "/spaces/:space_id/notebooks/:id", NotebookController, :update
    delete "/spaces/:space_id/notebooks/:id", NotebookController, :delete
    post "/spaces/:space_id/notebooks/import", NotebookController, :import_jupyter

    # Protocol CRUD
    post "/spaces/:space_id/protocols", ProtocolController, :create
    patch "/spaces/:space_id/protocols/:id", ProtocolController, :update
    delete "/spaces/:space_id/protocols/:id", ProtocolController, :delete

    # Dataset CRUD
    post "/spaces/:space_id/datasets", DatasetController, :create
    patch "/spaces/:space_id/datasets/:id", DatasetController, :update
    delete "/spaces/:space_id/datasets/:id", DatasetController, :delete

    # Dataset file management
    post "/spaces/:space_id/datasets/:dataset_id/files", DatasetController, :upload_file
    delete "/spaces/:space_id/datasets/:dataset_id/files/:file_id", DatasetController, :delete_file

    # Learn — authenticated endpoints
    post "/learn/units/:space_id/fork", LearnController, :fork_unit
    get "/learn/progress", LearnController, :my_progress
    get "/learn/progress/completed", LearnController, :completed_slugs
    patch "/learn/progress/:id/checkpoint", LearnController, :complete_checkpoint

    # Webhooks
    get "/webhooks", WebhookController, :index
    post "/webhooks", WebhookController, :create
    patch "/webhooks/:id", WebhookController, :update
    delete "/webhooks/:id", WebhookController, :delete
    get "/webhooks/:id/deliveries", WebhookController, :deliveries
  end

  # REST API v1 — convenience catch-all route (MUST be after all specific API scopes)
  scope "/api/v1", CyaneaWeb.Api.V1 do
    pipe_through :api_v1

    get "/:owner/:slug", SpaceController, :show_by_slug
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
      live "/forgot-password", AuthLive.ForgotPassword, :new
      live "/reset-password/:token", AuthLive.ResetPassword, :edit
      live "/confirm-email/:token", AuthLive.ConfirmEmail, :show
      live "/resend-confirmation", AuthLive.ResendConfirmation, :new
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
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
