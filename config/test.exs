use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :velocity, Velocity.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: System.get_env("POSTGRES_DB", "velocity_test#{System.get_env("MIX_TEST_PARTITION")}"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  queue_target: 2000,
  pool: Ecto.Adapters.SQL.Sandbox

config :tesla, adapter: Tesla.Mock

config :exq,
  queue_adapter: Exq.Adapters.Queue.Mock,
  start_on_application: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :velocity, VelocityWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :velocity,
  plugs_okta_jwt: VelocityWeb.Plugs.OktaJwt.Mock,
  plugs_okta_simple_token: VelocityWeb.Plugs.OktaSimpleToken.Mock,
  plugs_pega_simple_token: VelocityWeb.Plugs.PegaSimpleToken.Mock

config :velocity, Velocity.Notifications.Adapters.Email.Mailer, adapter: Bamboo.TestAdapter
