defmodule Contexla.Platform.Tools do
  @moduledoc "Authenticated boundary for requesting and executing versioned Tools."

  import Ecto.Query, warn: false

  alias Contexla.Platform.Accounts.{Scope, User}
  alias Contexla.Applications.Sdk.Error
  alias Contexla.Platform.Applications.ApplicationInstance
  alias Contexla.Platform.{Artifacts, Repo}
  alias Contexla.Platform.ToolRuntime.{Registry, Schema}
  alias Contexla.Platform.ToolRuntime.Runners.Native
  alias Contexla.Tools.Sdk.Requirement
  alias Contexla.Platform.Tools.{Catalog, Invocation, Tool}
  alias Contexla.Platform.Tools.Workers.ToolInvocationWorker

  def request(
        %Scope{user: %User{} = user},
        %ApplicationInstance{} = instance,
        tool_key,
        version,
        input,
        opts \\ []
      )
      when is_map(input) do
    with :ok <- Catalog.sync_bundled(),
         %Tool{} = tool <- find_tool(tool_key, version),
         :ok <- Schema.validate(input, tool.input_schema),
         {:ok, input_artifact} <- Artifacts.store_tool_input(%Scope{user: user}, instance, input) do
      now = DateTime.utc_now(:second)

      changeset =
        Invocation.request_changeset(%Invocation{}, %{
          tool_id: tool.id,
          input_artifact_id: input_artifact.id,
          application_instance_id: instance.id,
          invoked_by_user_id: user.id,
          parent_run_id: Keyword.get(opts, :parent_run_id),
          status: :pending,
          input: Schema.audit_projection(input, tool.input_schema),
          requested_at: now
        })

      Ecto.Multi.new()
      |> Ecto.Multi.insert(:invocation, changeset)
      |> Ecto.Multi.insert(:job, fn %{invocation: invocation} ->
        ToolInvocationWorker.new(%{"invocation_id" => invocation.id})
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{invocation: invocation}} -> {:ok, invocation}
        {:error, _step, reason, _changes} -> {:error, reason}
      end
    else
      nil -> {:error, :tool_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def fetch_invocation(
        %Scope{},
        %ApplicationInstance{id: instance_id},
        invocation_id
      ) do
    case Repo.get_by(Invocation,
           id: invocation_id,
           application_instance_id: instance_id
         ) do
      nil -> {:error, :not_found}
      invocation -> {:ok, Repo.preload(invocation, :tool)}
    end
  end

  def ensure_requirements(%ApplicationInstance{}, requirements) when is_list(requirements) do
    with :ok <- Catalog.sync_bundled() do
      Enum.reduce_while(requirements, :ok, fn %Requirement{} = requirement, :ok ->
        case find_tool(requirement.tool_id, requirement.version) do
          %Tool{} ->
            {:cont, :ok}

          nil when requirement.optional ->
            {:cont, :ok}

          nil ->
            {:halt,
             {:error, {:required_tool_unavailable, requirement.tool_id, requirement.version}}}
        end
      end)
    end
  end

  def execute(invocation_id, opts \\ []) do
    final_attempt? = Keyword.get(opts, :final_attempt?, false)

    case Repo.get(Invocation, invocation_id) |> Repo.preload([:tool, :input_artifact]) do
      nil ->
        {:discard, :tool_invocation_not_found}

      %Invocation{status: status} when status in [:succeeded, :failed, :timed_out, :cancelled] ->
        :ok

      invocation ->
        execute_invocation(invocation, final_attempt?)
    end
  end

  defp execute_invocation(invocation, final_attempt?) do
    invocation =
      transition!(invocation, %{
        status: :running,
        started_at: DateTime.utc_now(:second),
        error: nil
      })

    with {:ok, definition} <- Registry.fetch_tool(invocation.tool.key, invocation.tool.version) do
      context = %{invocation_id: invocation.id, permissions: invocation.tool.permissions}

      result =
        case definition.runtime do
          :native ->
            Native.run(
              definition.entrypoint,
              invocation_input(invocation),
              context,
              invocation.tool.timeout_ms
            )

          runtime ->
            {:execution_error, {:unsupported_tool_runtime, runtime}}
        end

      finish(invocation, result, final_attempt?)
    else
      :error -> retry_or_fail(invocation, :tool_definition_unavailable, final_attempt?)
    end
  end

  defp finish(invocation, {:ok, output}, _final_attempt?) do
    case Schema.validate(output, invocation.tool.output_schema) do
      :ok ->
        transition!(invocation, %{
          status: :succeeded,
          output: Schema.audit_projection(output, invocation.tool.output_schema),
          completed_at: DateTime.utc_now(:second)
        })

        :ok

      {:error, reason} ->
        fail(invocation, {:invalid_tool_output, reason})
    end
  end

  defp finish(invocation, {:tool_error, reason}, _final_attempt?), do: fail(invocation, reason)

  defp finish(invocation, {:execution_error, reason}, final_attempt?),
    do: retry_or_fail(invocation, reason, final_attempt?)

  defp retry_or_fail(invocation, reason, false) do
    transition!(invocation, %{status: :pending, error: Error.map(reason, "tool_execution_failed")})

    {:error, reason}
  end

  defp retry_or_fail(invocation, :timeout, true) do
    transition!(invocation, %{
      status: :timed_out,
      error: Error.map(:timeout, "tool_timed_out"),
      completed_at: DateTime.utc_now(:second)
    })

    {:error, :timeout}
  end

  defp retry_or_fail(invocation, reason, true) do
    fail(invocation, reason)
    {:error, reason}
  end

  defp fail(invocation, reason) do
    transition!(invocation, %{
      status: :failed,
      error: Error.map(reason, "tool_failed"),
      completed_at: DateTime.utc_now(:second)
    })

    :ok
  end

  defp transition!(invocation, attrs) do
    invocation |> Invocation.transition_changeset(attrs) |> Repo.update!()
  end

  defp invocation_input(invocation) do
    invocation.input_artifact
    |> Artifacts.local_path()
    |> File.read!()
    |> Jason.decode!()
  end

  defp find_tool(key, version),
    do: Repo.get_by(Tool, key: key, version: version, status: :active)
end
