defmodule Mix.Tasks.Contexla.Admin.Bootstrap do
  @shortdoc "Creates the first Contexla administrator"

  @moduledoc """
  Creates the first administrator from explicit environment variables:

      CONTEXLA_ADMIN_EMAIL=admin@example.com \
      CONTEXLA_ADMIN_PASSWORD='a unique temporary password' \
      mix contexla.admin.bootstrap

  The command refuses to run after any user exists. The administrator must
  change the bootstrap password on first login.
  """

  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(_args) do
    email = fetch_env!("CONTEXLA_ADMIN_EMAIL")
    password = fetch_env!("CONTEXLA_ADMIN_PASSWORD")

    case Contexla.Platform.Accounts.bootstrap_admin(%{email: email, password: password}) do
      {:ok, user} ->
        Mix.shell().info("Created administrator #{user.email}.")
        Mix.shell().info("The bootstrap password must be changed on first login.")

      {:error, :already_bootstrapped} ->
        Mix.raise("administrator bootstrap refused because a user already exists")

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {message, options} ->
            Enum.reduce(options, message, fn {key, value}, rendered ->
              String.replace(rendered, "%{#{key}}", to_string(value))
            end)
          end)

        Mix.raise("administrator bootstrap failed: #{inspect(errors)}")
    end
  end

  defp fetch_env!(name) do
    case System.fetch_env(name) do
      {:ok, value} when value != "" -> value
      _missing -> Mix.raise("#{name} is required")
    end
  end
end
