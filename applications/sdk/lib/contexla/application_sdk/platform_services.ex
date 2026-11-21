defmodule Contexla.ApplicationSDK.PlatformServices do
  @moduledoc """
  Host-side service contract consumed by `Contexla.ApplicationSDK.Runtime`.

  A platform implementation is injected at runtime. Concrete Applications
  compile only against this SDK contract.
  """

  alias Contexla.ApplicationSDK.Instance

  @callback create_instance(binary(), map()) :: {:ok, Instance.t()} | {:error, term()}
  @callback get_instance(binary(), binary()) :: {:ok, Instance.t()} | {:error, term()}
  @callback update_instance_config(binary(), binary(), map()) ::
              {:ok, Instance.t()} | {:error, term()}

  @callback get_artifact(binary(), binary()) :: {:ok, struct()} | {:error, term()}
  @callback list_artifacts(binary(), binary()) :: [struct()]
  @callback import_source(binary(), binary(), binary(), Path.t(), keyword()) ::
              {:ok, struct()} | {:error, term()}
  @callback artifact_path(struct()) :: Path.t()

  @callback fetch_adapter(binary()) :: {:ok, {struct(), struct()}} | {:error, term()}

  @callback invoke_capability(binary(), binary(), binary(), binary(), map()) ::
              {:ok, map(), struct()} | {:error, term()}
  @callback invoke_operation(binary(), binary(), binary(), map(), keyword()) :: term()
  @callback enqueue(module(), map()) :: {:ok, struct()} | {:error, term()}
end
