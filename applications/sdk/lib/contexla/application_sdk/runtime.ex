defmodule Contexla.ApplicationSDK.Runtime do
  @moduledoc "Dispatches trusted Application calls through platform-supplied service modules."

  @otp_app :contexla_application_sdk

  def service!(name) when is_atom(name) do
    @otp_app
    |> Application.fetch_env!(:services)
    |> Map.fetch!(name)
  end

  def call(service, function, arguments) when is_atom(service) and is_list(arguments) do
    apply(service!(service), function, arguments)
  end
end
