# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

config :logger, level: String.to_atom(System.get_env("LOG_LEVEL") || "info")

config :velocity,
  cors_allowed_origins_regex:
    System.get_env("CORS_ALLOWED_ORIGINS_REGEX") ||
      raise("""
      environment variable CORS_ALLOWED_ORIGINS_REGEX is missing.
      For example: "https?:\/\/.*.velocityglobal.com|https?:\/\/localhost:\d*"
      """),
  okta_issuer:
    System.get_env("OKTA_ISSUER") ||
      raise("""
      environment variable OKTA_ISSUER is missing.
      For example: "https://dev-283105.okta.com/oauth2/default"
      """),
  okta_api_host:
    System.get_env("OKTA_API_HOST") ||
      raise("""
      environment variable OKTA_API_HOST is missing.
      For example: "https://dev-283105-admin.okta.com"
      """),
  okta_api_token:
    System.get_env("OKTA_API_TOKEN") ||
      raise("""
      environment variable OKTA_API_TOKEN is missing.
      """),
  okta_events_token:
    System.get_env("OKTA_EVENTS_TOKEN") ||
      raise("""
      environment variable OKTA_EVENTS_TOKEN is missing.
      """),
  pega_api_token:
    System.get_env("PEGA_API_TOKEN") ||
      raise("""
      environment variable PEGA_API_TOKEN is missing.
      """),
  looker_sso_secret:
    System.get_env("LOOKER_SSO_SECRET") ||
      raise("""
      environment variable LOOKER_SSO_SECRET is missing.
      """),
  looker_embed_domain:
    System.get_env("LOOKER_EMBED_DOMAIN") ||
      raise("""
      environment variable LOOKER_EMBED_DOMAIN is missing.
      """),
  pega_api_host:
    System.get_env("PEGA_API_HOST") ||
      raise("""
      environment variable PEGA_API_HOST is missing.
      """),
  pega_basic_username:
    System.get_env("PEGA_BASIC_USERNAME") ||
      raise("""
      environment variable PEGA_BASIC_USERNAME is missing.
      """),
  pega_basic_password:
    System.get_env("PEGA_BASIC_PASSWORD") ||
      raise("""
      environment variable PEGA_BASIC_PASSWORD is missing.
      """),
  helpjuice_url:
    System.get_env("HELPJUICE_URL") ||
      raise("""
      environment variable HELPJUICE_URL is missing.
      """),
  helpjuice_api_token:
    System.get_env("HELPJUICE_API_TOKEN") ||
      raise("""
      environment variable HELPJUICE_API_TOKEN is missing.
      """),
  s3_bucket:
    System.get_env("API_AWS_S3_BUCKET") ||
      raise("""
      environment variable API_AWS_S3_BUCKET is missing.
      """),
  docusign_callback_url:
    System.get_env("DOCUSIGN_CALLBACK_URL") ||
      raise("""
      environment variable DOCUSIGN_CALLBACK_URL is missing.
      """)

config :ex_aws,
  access_key_id: System.get_env("API_AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("API_AWS_SECRET_ACCESS_KEY"),
  s3: [region: System.get_env("API_AWS_REGION")]

config :velocity, Velocity.Repo,
  # ssl: true,
  url:
    System.get_env("DATABASE_URL") ||
      raise("""
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true

config :velocity, VelocityWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") ||
      raise("""
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """)

# Docusign config - https://github.com/neilberkman/docusign_elixir
config :docusign,
  private_key:
    System.get_env("DOCUSIGN_PRIVATE_KEY_PATH") ||
      raise("""
      environment variable DOCUSIGN_PRIVATE_KEY_PATH is missing.
      """),
  token_expires_in: 3600,
  hostname:
    System.get_env("DOCUSIGN_HOSTNAME") ||
      raise("""
      environment variable DOCUSIGN_HOSTNAME is missing.
      """),
  client_id:
    System.get_env("DOCUSIGN_CLIENT_ID") ||
      raise("""
      environment variable DOCUSIGN_CLIENT_ID is missing.
      """),
  user_id:
    System.get_env("DOCUSIGN_USER_ID") ||
      raise("""
      environment variable DOCUSIGN_USER_ID is missing.
      """),
  account_id:
    System.get_env("DOCUSIGN_ACCOUNT_ID") ||
      raise("""
      environment variable DOCUSIGN_ACCOUNT_ID is missing.
      """),
  api_user_id:
    System.get_env("DOCUSIGN_API_USER_ID") ||
      raise("""
      environment variable DOCUSIGN_API_USER_ID is missing.
      """)

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

# defp System.get_env_var!(ENV_VAR) do
#   System.get_env(ENV_VAR) ||
#     raise("""
#     environment variable #{ENV_VAR} is missing.
#     """)
# end
