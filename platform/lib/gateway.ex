defmodule Contexla.Platform.Gateway do
  @moduledoc "Dispatches fetch requests to the correct adapter based on a connection's adapter_key."

  alias Contexla.Platform.Connections.Connection

  @adapters %{
    "generic_http_json" => Contexla.Platform.Gateway.Adapters.GenericHttpJson,
    "generic_http_html" => Contexla.Platform.Gateway.Adapters.GenericHttpHtml,
    "csv" => Contexla.Platform.Gateway.Adapters.Csv
  }

  @doc "Fetch a URL using the adapter declared on the connection."
  @spec fetch(url :: String.t(), connection :: Connection.t()) ::
          {:ok, map()} | {:error, term()}
  def fetch(url, %Connection{} = connection) do
    case Map.fetch(@adapters, connection.adapter_key) do
      {:ok, adapter} -> adapter.fetch(url, connection)
      :error -> {:error, {:unknown_adapter, connection.adapter_key}}
    end
  end

  @doc "Returns the list of available adapters as [{adapter_key, label}] for use in UI selectors."
  @spec available_adapters() :: [{String.t(), String.t()}]
  def available_adapters do
    @adapters
    |> Enum.map(fn {key, module} -> {key, module.label()} end)
    |> Enum.sort_by(&elem(&1, 1))
  end

  @doc "Returns the connection field specs for a given adapter_key."
  @spec connection_fields(String.t()) :: [map()]
  def connection_fields(adapter_key) do
    case Map.fetch(@adapters, adapter_key) do
      {:ok, adapter} -> adapter.connection_fields()
      :error -> []
    end
  end
end
