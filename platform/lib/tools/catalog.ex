defmodule Contexla.Platform.Tools.Catalog do
  @moduledoc "Synchronizes trusted Tool definitions into the PostgreSQL catalog."

  alias Contexla.Platform.Repo
  alias Contexla.Platform.Tools.Tool
  alias Contexla.Platform.ToolRuntime.Registry

  @spec sync_bundled() :: :ok | {:error, term()}
  def sync_bundled do
    Repo.transaction(fn ->
      Registry.tools()
      |> Enum.reduce_while(:ok, fn definition, :ok ->
        case sync_tool(definition) do
          :ok -> {:cont, :ok}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        :ok -> :ok
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
    |> case do
      {:ok, :ok} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp sync_tool(definition) do
    attrs = attrs(definition)

    case Repo.get_by(Tool, key: definition.id, version: definition.version) do
      nil ->
        insert(Tool.changeset(%Tool{}, attrs))

      %Tool{definition_digest: digest} when digest == attrs.definition_digest ->
        :ok

      %Tool{} = tool ->
        if Mix.env() == :dev do
          case Repo.update(Tool.changeset(tool, attrs)) do
            {:ok, _record} -> :ok
            {:error, changeset} -> {:error, changeset}
          end
        else
          {:error, {:tool_definition_drift, definition.id, definition.version}}
        end
    end
  end

  defp attrs(definition) do
    definition
    |> Map.from_struct()
    |> Map.put(:key, definition.id)
    |> Map.delete(:id)
    |> Map.update!(:entrypoint, &entrypoint/1)
    |> Map.put(:definition_digest, digest(definition))
    |> Map.put(:status, :active)
  end

  defp entrypoint(value) when is_atom(value), do: Atom.to_string(value)
  defp entrypoint(value) when is_list(value), do: Jason.encode!(value)
  defp entrypoint(value), do: value

  defp digest(definition) do
    definition
    |> Map.from_struct()
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp insert(changeset) do
    case Repo.insert(changeset) do
      {:ok, _record} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end
end
