defmodule Contexla.IntegrationSDK.SourceAdapter do
  @moduledoc """
  Contract for an Adapter that validates an external evidence source before the
  platform records it as an Artifact.

  Validation must not mutate the source or persist platform state.
  """

  @type validation :: %{
          required(:sha256) => String.t(),
          required(:byte_size) => non_neg_integer(),
          required(:source_type) => String.t(),
          required(:manifest) => map(),
          required(:files) => [map()]
        }

  @callback validate_source(Path.t(), keyword()) ::
              {:ok, validation()} | {:error, term()}
end
