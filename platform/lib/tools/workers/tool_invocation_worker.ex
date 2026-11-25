defmodule Contexla.Platform.Tools.Workers.ToolInvocationWorker do
  @moduledoc "Durably executes one pending Tool Invocation."

  use Oban.Worker, queue: :tool_invocations, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"invocation_id" => id}, attempt: attempt, max_attempts: max}) do
    Contexla.Platform.Tools.execute(id, final_attempt?: attempt >= max)
  end
end
