defmodule Contexla.Applications.ContentIntegrityMonitor.Workers.RunWorker do
  @moduledoc "Thin durable worker for one content-integrity Run."

  use Oban.Worker, queue: :content_integrity_monitor_default, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"integrity_run_id" => run_id}}) do
    Contexla.Applications.ContentIntegrityMonitor.Executor.perform(run_id)
  end
end
