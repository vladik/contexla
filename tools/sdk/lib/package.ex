defmodule Contexla.Tools.Sdk.Package do
  @moduledoc "A package that registers immutable Tool definitions."

  alias Contexla.Tools.Sdk.Tool
  @callback tools() :: [Tool.t()]
end
