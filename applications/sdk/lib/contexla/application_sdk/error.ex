defmodule Contexla.ApplicationSDK.Error do
  @moduledoc """
  Converts internal failure terms into bounded codes safe for persistence and UI.

  Arbitrary strings, structs, changesets, exception messages, and nested terms
  are never copied into the returned value.
  """

  @spec code(term(), String.t()) :: String.t()
  def code(reason, fallback \\ "operation_failed")

  def code(reason, _fallback) when is_atom(reason), do: Atom.to_string(reason)

  def code(reason, fallback) when is_tuple(reason) and tuple_size(reason) > 0 do
    case elem(reason, 0) do
      code when is_atom(code) -> Atom.to_string(code)
      _other -> fallback
    end
  end

  def code(_reason, fallback), do: fallback

  @spec map(term(), String.t()) :: %{String.t() => String.t()}
  def map(reason, fallback \\ "operation_failed"), do: %{"code" => code(reason, fallback)}
end
