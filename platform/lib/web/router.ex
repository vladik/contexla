defmodule Contexla.Platform.Web.Router do
  use Contexla.Platform.Web, :router

  import Contexla.Platform.Web.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Contexla.Platform.Web.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug :assign_root_shell
  end

  defp assign_root_shell(conn, _opts) do
    mode = if conn.request_path == "/users/log-in", do: :public, else: :platform

    instances =
      case conn.assigns[:current_scope] do
        %Contexla.Platform.Accounts.Scope{user: %Contexla.Platform.Accounts.User{}} = scope ->
          Contexla.Platform.Applications.list_navigation_instances(scope)

        _other ->
          []
      end

    conn
    |> Plug.Conn.assign(:root_shell, mode)
    |> Plug.Conn.assign(:current_path, conn.request_path)
    |> Plug.Conn.assign(:navigation_instances, instances)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/health", Contexla.Platform.Web do
    pipe_through :api

    get "/live", HealthController, :live
    get "/ready", HealthController, :ready
  end

  # Other scopes may use custom stacks.
  # scope "/api", Contexla.Platform.Web do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:contexla, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Contexla.Platform.Web.Telemetry
    end
  end

  ## Authentication routes

  scope "/", Contexla.Platform.Web do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{Contexla.Platform.Web.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", Contexla.Platform.Web do
    pipe_through [:browser, :require_authenticated_user, :require_password_change_completed]

    get "/applications/new/:application_id/:surface", ApplicationSurfaceController, :new

    get "/application-operations/:instance_id/:operation_id",
        ApplicationOperationController,
        :read

    post "/application-operations/:instance_id/:operation_id",
         ApplicationOperationController,
         :execute

    live_session :platform,
      on_mount: [{Contexla.Platform.Web.UserAuth, :require_authenticated}] do
      live "/", ApplicationLive.Index, :index
      live "/applications", ApplicationLive.Index, :index
      live "/applications/new", ApplicationLive.New, :new
      live "/applications/:instance_id/settings", ApplicationInstanceSettingsLive, :edit
      live "/connections", ConnectionLive.Index, :index
      live "/settings", PlatformSettingsLive, :index
    end

    get "/applications/:instance_id", ApplicationSurfaceController, :show_default
    get "/applications/:instance_id/:surface", ApplicationSurfaceController, :show
  end

  scope "/", Contexla.Platform.Web do
    pipe_through [
      :browser,
      :require_authenticated_user,
      :require_password_change_completed,
      :require_admin
    ]

    live_session :installation_admin,
      on_mount: [{Contexla.Platform.Web.UserAuth, :require_admin}] do
      live "/operations", OperationsLive, :index
    end

    get "/operations/support-bundle", SupportBundleController, :download
  end

  scope "/", Contexla.Platform.Web do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{Contexla.Platform.Web.UserAuth, :mount_current_scope}] do
      live "/users/log-in", UserLive.Login, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
