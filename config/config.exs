# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :velocity,
  ecto_repos: [Velocity.Repo],
  looker_sso_secret:
    System.get_env(
      "LOOKER_SSO_SECRET",
      ""
    ),
  okta_events_token: System.get_env("OKTA_EVENTS_TOKEN", "supersecuretoken"),
  okta_client_id: System.get_env("OKTA_CLIENT_ID", "0oa56obkugOhYhWh3357"),
  okta_mobile_client_id: System.get_env("OKTA_MOBILE_CLIENT_ID", "0oa56obkugOhYhWh3357"),
  okta_issuer: System.get_env("OKTA_ISSUER", "https://dev-283105.okta.com/oauth2/default"),
  looker_embed_domain: System.get_env("LOOKER_EMBED_DOMAIN", "http://localhost"),
  cors_allowed_origins_regex:
    System.get_env(
      "CORS_ALLOWED_ORIGINS_REGEX",
      "https?:\/\/.*.velocityglobal.com|https?:\/\/localhost:\d*"
    ),
  okta_api_host: System.get_env("OKTA_API_HOST", "https://dev-283105-admin.okta.com"),
  okta_api_token: System.get_env("OKTA_API_TOKEN", "needs_okta_token"),
  pega_api_token: System.get_env("PEGA_API_TOKEN", "needs_pega_token"),
  notifications: [
    email: Velocity.Notifications.Adapters.Email,
    mobile: Velocity.Notifications.Adapters.Expo
  ],
  helpjuice_url: System.get_env("HELPJUICE_URL", "https://velocity-global.helpjuice.com"),
  helpjuice_api_token: System.get_env("HELPJUICE_API_TOKEN", "nottherealtoken"),
  compile_env: Mix.env(),
  s3_bucket: System.get_env("API_AWS_S3_BUCKET", "not-the-bucket"),
  docusign_callback_url:
    System.get_env("DOCUSIGN_CALLBACK_URL", "http://localhost:8080/docusign/callback")

config :ex_aws,
  access_key_id: System.get_env("API_AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("API_AWS_SECRET_ACCESS_KEY"),
  s3: [region: System.get_env("API_AWS_REGION")]

config :tesla, adapter: Tesla.Adapter.Hackney

config :exq,
  name: Exq,
  start_on_application: false,
  url: System.get_env("REDIS_URL", "redis://localhost:6379"),
  namespace: "exq",
  concurrency: :infinite,
  queues: ["default"],
  poll_timeout: 50,
  scheduler_poll_timeout: 200,
  scheduler_enable: true,
  max_retries: 5,
  mode: :default,
  shutdown_timeout: 5000

# config :velocity, Velocity.Notifications.Adapters.Email.Mailer, adapter: Bamboo.SesAdapter
config :velocity, Velocity.Notifications.Adapters.Email.Mailer, adapter: Bamboo.LocalAdapter

# Configures the endpoint
config :velocity, VelocityWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "cOPFNK5ctc30OrimYhsey7VqNKt3dzSo3QNPucojlbexsyPKrho008wSmwcFgFhS",
  render_errors: [view: VelocityWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Velocity.PubSub,
  live_view: [signing_salt: "v7xVgM6D"]

# Configures Elixir's Logger
config :logger, :console,
  utc_log: true,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Docusign config - https://github.com/neilberkman/docusign_elixir
config :docusign,
  private_key: System.get_env("DOCUSIGN_PRIVATE_KEY_PATH"),
  token_expires_in: 3600,
  hostname: System.get_env("DOCUSIGN_HOSTNAME"),
  client_id: System.get_env("DOCUSIGN_CLIENT_ID"),
  user_id: System.get_env("DOCUSIGN_USER_ID"),
  account_id: System.get_env("DOCUSIGN_ACCOUNT_ID"),
  api_user_id: System.get_env("DOCUSIGN_API_USER_ID")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
