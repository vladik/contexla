defmodule Contexla.Applications.DigitalEstateAssessment.Workers.AssessmentWorker do
  @moduledoc "Thin durable worker for one Assessment Run."

  use Oban.Worker, queue: :application_runs, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"assessment_run_id" => run_id}}) do
    Contexla.Applications.DigitalEstateAssessment.Executor.perform(run_id)
  end
end
