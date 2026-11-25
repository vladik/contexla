defmodule Contexla.Platform.Diagnostics do
  @moduledoc "Bounded operational checks shared by health endpoints and release tooling."

  alias Contexla.Platform.Repo

  @type result :: %{status: :ok | :error, checks: %{atom() => :ok | :error}}

  @spec check() :: result()
  def check do
    checks = %{
      database: database(),
      artifact_storage: artifact_storage(),
      oban: oban(),
      package_registry: process(Contexla.Platform.Packages.Registry),
      tool_registry: process(Contexla.Platform.ToolRuntime.Registry)
    }

    status = if Enum.all?(checks, fn {_name, result} -> result == :ok end), do: :ok, else: :error
    %{status: status, checks: checks}
  end

  defp database do
    case Ecto.Adapters.SQL.query(Repo, "SELECT 1", []) do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
    end
  rescue
    _error -> :error
  catch
    _kind, _reason -> :error
  end

  defp artifact_storage do
    :contexla
    |> Application.fetch_env!(:artifact_storage_path)
    |> File.dir?()
    |> if(do: :ok, else: :error)
  end

  defp oban do
    _config = Oban.config(Oban)
    :ok
  rescue
    _error -> :error
  catch
    :exit, _reason -> :error
  end

  defp process(name) do
    case Process.whereis(name) do
      pid when is_pid(pid) -> :ok
      nil -> :error
    end
  end
end
