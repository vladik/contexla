import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :pbkdf2_elixir, :rounds, 1

config :contexla,
  application_packages: [Contexla.Platform.Test.Support.PackageFixtures.TestApplication],
  integration_packages: [Contexla.Platform.Test.Support.PackageFixtures.TestIntegration],
  artifact_storage_path:
    Path.expand(
      "../.tmp/test-artifacts/#{System.get_env("MIX_TEST_PARTITION", "default")}",
      __DIR__
    )

config :contexla, Oban, testing: :manual, queues: false

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :contexla, Contexla.Platform.Repo,
  username: "contexla",
  password: "contexla_dev",
  hostname: "localhost",
  port: String.to_integer(System.get_env("POSTGRES_PORT", "15432")),
  database: "contexla_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :contexla, Contexla.Platform.Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "pm+Cao/q05sQrVthqHqFCVoSjlXQJRS9w4q31i2Glntmnf+GJOqEGWKovb/64+WO",
  server: false

# Print only warnings and errors during test
config :contexla, :credential_encryption_key,
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
