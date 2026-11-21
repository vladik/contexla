defmodule Contexla.ApplicationSDK.Runtime do
  @moduledoc """
  Typed access to the bounded runtime services supplied by the Contexla host.

  Applications use these functions instead of depending on platform modules or
  dynamically naming platform functions. The host remains responsible for
  actor scoping, authorization, validation, audit, and execution policy.
  """

  alias Contexla.ApplicationSDK.Instance

  @otp_app :contexla_application_sdk

  @spec repo!() :: module()
  def repo!, do: service!(:repo)

  @spec create_instance(binary(), map()) :: {:ok, Instance.t()} | {:error, term()}
  def create_instance(actor_id, attrs),
    do: platform().create_instance(actor_id, attrs)

  @spec get_instance(binary(), binary()) :: {:ok, Instance.t()} | {:error, term()}
  def get_instance(actor_id, instance_id),
    do: platform().get_instance(actor_id, instance_id)

  @spec update_instance_config(binary(), binary(), map()) ::
          {:ok, Instance.t()} | {:error, term()}
  def update_instance_config(actor_id, instance_id, config),
    do: platform().update_instance_config(actor_id, instance_id, config)

  @spec get_artifact(binary(), binary()) :: {:ok, struct()} | {:error, term()}
  def get_artifact(actor_id, artifact_id),
    do: platform().get_artifact(actor_id, artifact_id)

  @spec list_artifacts(binary(), binary()) :: [struct()]
  def list_artifacts(actor_id, instance_id),
    do: platform().list_artifacts(actor_id, instance_id)

  @spec import_source(binary(), binary(), binary(), Path.t(), keyword()) ::
          {:ok, struct()} | {:error, term()}
  def import_source(actor_id, instance_id, adapter_id, path, options \\ []),
    do: platform().import_source(actor_id, instance_id, adapter_id, path, options)

  @spec artifact_path(struct()) :: Path.t()
  def artifact_path(artifact), do: platform().artifact_path(artifact)

  @spec fetch_adapter(binary()) :: {:ok, {struct(), struct()}} | {:error, term()}
  def fetch_adapter(adapter_id), do: platform().fetch_adapter(adapter_id)

  @spec invoke_capability(binary(), binary(), binary(), binary(), map()) ::
          {:ok, map(), struct()} | {:error, term()}
  def invoke_capability(actor_id, instance_id, capability_id, version, input),
    do:
      platform().invoke_capability(
        actor_id,
        instance_id,
        capability_id,
        version,
        input
      )

  @spec invoke_operation(binary(), binary(), binary(), map(), keyword()) :: term()
  def invoke_operation(actor_id, instance_id, operation_id, input, options \\ []),
    do: platform().invoke_operation(actor_id, instance_id, operation_id, input, options)

  @spec enqueue(module(), map()) :: {:ok, struct()} | {:error, term()}
  def enqueue(worker, args), do: platform().enqueue(worker, args)

  defp platform, do: service!(:platform)

  defp service!(name) when is_atom(name) do
    @otp_app
    |> Application.fetch_env!(:services)
    |> Map.fetch!(name)
  end
end
