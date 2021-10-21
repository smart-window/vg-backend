defmodule VelocityWeb.Router do
  use VelocityWeb, :router

  alias VelocityWeb.Controllers.CsvController
  alias VelocityWeb.Controllers.HealthController
  alias VelocityWeb.Controllers.ImportController
  alias VelocityWeb.Controllers.LookerController
  alias VelocityWeb.Controllers.OktaController
  alias VelocityWeb.Controllers.Pto.AccrualPoliciesController
  alias VelocityWeb.Controllers.Pto.LedgersController
  alias VelocityWeb.Controllers.Pto.TransactionsController
  alias VelocityWeb.Controllers.Pto.UserPoliciesController
  alias VelocityWeb.EmailController
  alias VelocityWeb.Plugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :rest do
    plug :accepts, ["json"]
    plug Plugs.AtomKeys
  end

  pipeline :authenticated_rest do
    plug :accepts, ["json"]
    plug Plugs.AtomKeys
    plug Application.get_env(:velocity, :plugs_okta_jwt, Plugs.OktaJwt)
    plug Plugs.RestContext
  end

  pipeline :graphql do
    plug :accepts, ["json"]
    plug Application.get_env(:velocity, :plugs_okta_jwt, Plugs.OktaJwt)
    plug Plugs.GraphqlContext
  end

  pipeline :okta_events do
    plug :accepts, ["json"]
    plug Application.get_env(:velocity, :plugs_okta_simple_token, Plugs.OktaSimpleToken)
  end

  pipeline :pega_simple do
    plug Application.get_env(:velocity, :plugs_pega_simple_token, Plugs.PegaSimpleToken)
  end

  scope "/" do
    pipe_through :rest

    get "/is_it_up", HealthController, :is_it_up, log: false
    get "/ready", HealthController, :ready, log: false
    get "/user_check", OktaController, :user_check
  end

  scope "/" do
    pipe_through :browser
    get "/email/:template", EmailController, :render_template
  end

  scope "/" do
    pipe_through :graphql

    forward "/graphql", Absinthe.Plug,
      schema: VelocityWeb.Schema,
      socket: VelocityWeb.UserSocket

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: VelocityWeb.Schema,
      socket: VelocityWeb.UserSocket
  end

  scope "/" do
    pipe_through :authenticated_rest

    post "/looker/sso_embed_url", LookerController, :sso_embed_url
    post "/import/email_templates", ImportController, :email_templates
    post "/import/notification_templates", ImportController, :notification_templates
    post "/import/process_templates", ImportController, :process_templates
    get "/csv/time_entries", CsvController, :time_entries
    get "/csv/training", CsvController, :training
    get "/csv/form_field_values", CsvController, :form_field_values
    get "/pto/ledgers/export_all", LedgersController, :export_all

    delete "/pto/user/:user_id/policy/:policy_id/ledgers/delete_all",
           LedgersController,
           :delete_all
  end

  scope "/okta/events" do
    pipe_through :okta_events

    post "/", OktaController, :received
    get "/*path", OktaController, :verify
  end

  scope "/pto" do
    pipe_through :rest
    pipe_through :pega_simple

    post "/user_policies", UserPoliciesController, :assign_user_policy
    delete "/user_policies", UserPoliciesController, :remove_user_policies
    get "/user_policies", UserPoliciesController, :list
    post "/transactions/nightly_accrual", TransactionsController, :nightly_accrual
    post "/transactions/taken", TransactionsController, :taken
    post "/transactions/manual_adjustment", TransactionsController, :manual_adjustment
    post "/transactions/withdrawn", TransactionsController, :withdrawn
    get "/ledgers", LedgersController, :list
    post "/policies", AccrualPoliciesController, :create
    get "/policies", AccrualPoliciesController, :all
    put "/policies/:pega_policy_id", AccrualPoliciesController, :update
    delete "/policies/:pega_policy_id", AccrualPoliciesController, :delete

    delete "/policies/:pega_policy_id/levels/:pega_level_id",
           AccrualPoliciesController,
           :delete_level

    get "/policies/:pega_policy_id", AccrualPoliciesController, :get
    get "/ledgers/summary", LedgersController, :by_user
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Application.get_env(:velocity, :compile_env) in [:dev, :test, :qa, :prod, :production] do
    import Phoenix.Router

    forward "/sent_emails", Bamboo.SentEmailViewerPlug

    # scope "/" do
    #  pipe_through [:fetch_session, :protect_from_forgery]
    #  live_dashboard "/dashboard", metrics: VelocityWeb.Telemetry
    # end
  end
end
