# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :contexla, :scopes,
  user: [
    default: true,
    module: Contexla.Platform.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :binary_id,
    schema_table: :users,
    test_data_fixture: Contexla.Platform.Test.Support.Fixtures.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :contexla,
  ecto_repos: [Contexla.Platform.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true],
  application_packages: [],
  integration_packages: [],
  tool_packages: [Contexla.Tools.Bundled.Package],
  artifact_storage_path: Path.expand("../.tmp/artifacts", __DIR__)

config :contexla, Oban,
  engine: Oban.Engines.Basic,
  repo: Contexla.Platform.Repo,
  queues: [application_runs: 4, tool_invocations: 4]

config :contexla_application_sdk,
  services: %{repo: Contexla.Platform.Repo, platform: Contexla.Platform.ApplicationServices}

# Configure the endpoint
config :contexla, Contexla.Platform.Web.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: Contexla.Platform.Web.ErrorHTML, json: Contexla.Platform.Web.ErrorJSON],
    layout: false
  ],
  pubsub_server: Contexla.PubSub,
  live_view: [signing_salt: "YJjtYj+k"]

# Configure LiveView
config :phoenix_live_view,
  # the attribute set on all root tags. Used for Phoenix.LiveView.ColocatedCSS.
  root_tag_attribute: "phx-r"

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  contexla: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.3.0",
  contexla: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Email delivery is retained for authenticated account settings. Public
# registration and magic-link login are not exposed by Contexla.
config :contexla, Contexla.Platform.Mailer, adapter: Swoosh.Adapters.Local
config :swoosh, :api_client, false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
