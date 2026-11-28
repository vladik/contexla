defmodule Contexla.Applications.Sdk.Operation do
  @moduledoc """
  An operation exposed by an Application to the platform, UI, API, and agents.

  Operations are the public entry points of an Application — the declared things it
  can do when triggered from outside. Think of them as typed remote procedure calls:
  they have a name, an input contract, and execution rules. The platform enforces
  the contract before ever calling Application code.

  ## How it works

  1. Declare the operation in `contexla-application.json` under the matching type array.
  2. Add a matching `execute_operation/3` clause in your Package module that pattern
     matches on the id string.
  3. The platform calls `execute_operation(id, instance, validated_input)` after
     validating input, checking approval, and recording an invocation.

  ## Types

  - `:job` — long-running async work backed by an Oban Worker. The `execute_operation`
    clause enqueues the Worker and returns `{:ok, %{}}`. Transported via POST.
    Requires `queue`, `max_attempts`, and `timeout_seconds`.
  - `:command` — fast synchronous state change. Returns the result directly.
    Transported via POST.
  - `:query` — read-only, returns data or a download. Transported via GET or POST.

  ## Fields

  - `:id` — unique string, used to route to the matching `execute_operation` clause.
    Convention: `"<app_name>.<action>"`, e.g. `"integrity.run"`.
  - `:name` — human-readable label shown in the UI and read by agents.
  - `:description` — explains what the operation does and when to use it.
    Agents use this to decide which operation to call.
  - `:type` — `:job`, `:command`, or `:query`.
  - `:queue` — (jobs only) which named queue the Worker runs on.
    Namespaced at runtime as `<otp_application>_<queue>`, e.g. `content_integrity_monitor_default`.
  - `:max_attempts` — (jobs only) Oban retry count for the enqueued Worker.
  - `:timeout_seconds` — (jobs only) how long before the invocation is marked timed out.
  - `:requires_approval` — when true, the platform shows a confirmation dialog
    before calling Application code. Use for destructive or consequential actions.
  - `:input_schema` — JSON Schema map validated by the platform before dispatch.
    Only declare what your Application actually needs. Use `additionalProperties: false`
    to reject unexpected fields.

  ## What belongs in the manifest

  Only operations triggered from outside the Application: UI buttons, API calls,
  agent commands, scheduled triggers. Internal functions, Worker steps, and
  Processor calls are not operations — they stay as plain Elixir functions called
  directly from your own code.
  """

  @enforce_keys [:id, :name]
  defstruct [
    :id,
    :name,
    type: :command,
    description: "",
    queue: nil,
    max_attempts: nil,
    timeout_seconds: nil,
    requires_approval: false,
    input_schema: %{"type" => "object", "properties" => %{}}
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          type: :job | :command | :query,
          description: String.t(),
          queue: atom() | nil,
          max_attempts: pos_integer() | nil,
          timeout_seconds: pos_integer() | nil,
          requires_approval: boolean(),
          input_schema: map()
        }

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{type: :job} = op) do
    valid? =
      non_empty?(op.id) and
        non_empty?(op.name) and
        is_binary(op.description) and
        is_atom(op.queue) and not is_nil(op.queue) and
        is_integer(op.max_attempts) and op.max_attempts > 0 and
        is_integer(op.timeout_seconds) and op.timeout_seconds > 0 and
        is_boolean(op.requires_approval) and
        is_map(op.input_schema)

    if valid?, do: :ok, else: {:error, {:invalid_operation, op.id}}
  end

  def validate(%__MODULE__{type: type} = op) when type in [:command, :query] do
    valid? =
      non_empty?(op.id) and
        non_empty?(op.name) and
        is_binary(op.description) and
        is_boolean(op.requires_approval) and
        is_map(op.input_schema)

    if valid?, do: :ok, else: {:error, {:invalid_operation, op.id}}
  end

  def validate(%__MODULE__{} = op) do
    {:error, {:invalid_operation_type, op.id}}
  end

  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
end
