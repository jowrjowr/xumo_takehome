# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# config :xumo,
#   ecto_repos: [Xumo.Repo]

# Configures the endpoint
config :xumo, XumoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jcp1C9T7yZxZLBNpTNLfTvYBgf2UAr01f597eKxbjVKVeKwFFIOhDwwf24MtLN9t",
  render_errors: [view: XumoWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Xumo.PubSub,
  live_view: [signing_salt: "yu+dtrij"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tailwind, :version, "3.2.7"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
