defmodule Contexla.ApplicationSDK.Surface do
  @moduledoc """
  A UI surface contributed by an Application behind a platform-owned route.

  Surfaces are dynamically rendered by a generic controller rather than mounted
  directly in the Phoenix router. Their LiveView `mount/3` callback therefore
  receives route and query values through `session["surface_params"]`; it must
  not depend on the first `mount/3` argument containing router params.
  """

  @enforce_keys [:id, :path, :module, :role]
  defstruct [:id, :path, :module, :role, :label]

  @type role :: :new | :instance
  @type t :: %__MODULE__{
          id: atom(),
          path: String.t(),
          module: module(),
          role: role(),
          label: String.t() | nil
        }

  def validate(%__MODULE__{} = surface) do
    valid? =
      is_atom(surface.id) and is_binary(surface.path) and is_atom(surface.module) and
        surface.role in [:new, :instance] and
        (is_nil(surface.label) or is_binary(surface.label)) and
        valid_path?(surface.path)

    if valid?, do: :ok, else: {:error, {:invalid_surface, surface.id}}
  end

  defp valid_path?(path) do
    path != "" and not String.contains?(path, ["/", "..", "\\"])
  end
end
