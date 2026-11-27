defmodule Contexla.Platform.Gateway.Adapter do
  @moduledoc "Behaviour every Gateway adapter must implement."

  alias Contexla.Platform.Connections.Connection

  @type fetch_result ::
          {:ok,
           %{
             document: map() | binary() | list(),
             body: binary(),
             status: integer(),
             media_type: String.t(),
             sha256: String.t(),
             excerpt: String.t(),
             fetched_at: DateTime.t()
           }}
          | {:error, term()}

  @type field_spec :: %{
          key: atom(),
          label: String.t(),
          type: :text | :password | :select,
          secret: boolean(),
          options: list() | nil,
          show_when: {atom(), String.t()} | nil
        }

  @doc "Fetch a URL using this adapter, applying auth from the connection."
  @callback fetch(url :: String.t(), connection :: Connection.t()) :: fetch_result()

  @doc "Field specifications for the connection form."
  @callback connection_fields() :: [field_spec()]

  @doc "Human-readable label shown in the connection adapter selector."
  @callback label() :: String.t()
end
