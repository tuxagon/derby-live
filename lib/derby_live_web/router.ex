defmodule DerbyLiveWeb.Router do
  use DerbyLiveWeb, :router

  import DerbyLiveWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DerbyLiveWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]

    post "/api/data", DerbyLiveWeb.DataController, :import
  end

  scope "/", DerbyLiveWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/auth", AuthController, :index
    post "/auth/login", AuthController, :login
    delete "/auth/logout", AuthController, :logout
    get "/auth/verify/:token", AuthController, :verify

    live "/heats", HeatLive
    live "/racers", RacerLive
  end

  ## Authentication routes

  scope "/", DerbyLiveWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{DerbyLiveWeb.UserAuth, :ensure_authenticated}] do
      live "/events", EventLive, :index
      live "/events/new", EventLive, :new
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", DerbyLiveWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:derby_live, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DerbyLiveWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
