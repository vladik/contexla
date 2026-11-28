defmodule Contexla.Platform.SupportBundles do
  @moduledoc """
  Builds an in-memory, administrator-authorized diagnostic bundle.

  Every entry is assembled from an explicit allow-list. The bundle never reads
  logs, credentials, Artifacts, invocation payloads, Oban arguments, exception
  details, or Application-owned domain tables.
  """

  alias Contexla.Platform.Accounts.{Scope, User}
  alias Contexla.Platform.{AuditEvents, Operations, Repo}

  @schema_version "1"
  @content_type "application/zip"

  @type bundle :: %{
          id: Ecto.UUID.t(),
          filename: String.t(),
          content_type: String.t(),
          contents: binary(),
          sha256: String.t()
        }

  @spec generate(Scope.t()) :: {:ok, bundle()} | {:error, term()}
  def generate(%Scope{user: %User{role: :admin}} = scope) do
    bundle_id = Ecto.UUID.generate()
    generated_at = DateTime.utc_now(:second)

    with {:ok, snapshot} <- Operations.support_snapshot(scope),
         {:ok, contents} <- archive(bundle_id, generated_at, snapshot),
         {:ok, _event} <- record_generation(scope, bundle_id) do
      {:ok,
       %{
         id: bundle_id,
         filename: filename(generated_at),
         content_type: @content_type,
         contents: contents,
         sha256: sha256(contents)
       }}
    end
  end

  def generate(%Scope{}), do: {:error, :forbidden}

  defp record_generation(scope, bundle_id) do
    AuditEvents.record(scope, %{
      action: "support_bundle.generated",
      subject_type: "support_bundle",
      subject_id: bundle_id,
      metadata: %{"schema_version" => @schema_version}
    })
  end

  defp archive(bundle_id, generated_at, snapshot) do
    entries = [
      {"health.json", encode(%{diagnostics: snapshot.diagnostics, counts: snapshot.counts})},
      {"runtime.json", encode(runtime(snapshot.packages))},
      {"activity.json", encode(activity(snapshot))}
    ]

    manifest = %{
      schema_version: @schema_version,
      bundle_id: bundle_id,
      generated_at: DateTime.to_iso8601(generated_at),
      files:
        Enum.map(entries, fn {name, contents} ->
          %{name: name, byte_size: byte_size(contents), sha256: sha256(contents)}
        end),
      exclusions: [
        "credentials",
        "invocation_payloads",
        "job_arguments",
        "artifact_contents",
        "application_domain_data",
        "raw_logs",
        "exception_details",
        "user_email_addresses"
      ]
    }

    zip_entries = [{"manifest.json", encode(manifest)} | entries]

    case :zip.create(
           ~c"contexla-support-bundle.zip",
           Enum.map(zip_entries, fn {name, contents} -> {String.to_charlist(name), contents} end),
           [:memory]
         ) do
      {:ok, {_name, binary}} -> {:ok, binary}
      {:error, reason} -> {:error, {:support_bundle_archive_failed, reason}}
    end
  end

  defp runtime(packages) do
    %{
      platform: %{
        version: platform_version(),
        elixir: System.version(),
        otp: System.otp_release()
      },
      migrations: migration_status(packages.applications),
      packages: packages
    }
  end

  defp activity(snapshot) do
    %{
      captured_at: snapshot.captured_at,
      operation_invocations: snapshot.operation_invocations,
      jobs: snapshot.jobs,
      audit_events: snapshot.audit_events
    }
  end

  defp migration_status(applications) do
    schemas =
      [
        %{owner: "platform", schema: "public"}
        | Enum.flat_map(applications, fn application ->
            case application.database_schema do
              schema when is_binary(schema) -> [%{owner: application.id, schema: schema}]
              nil -> []
            end
          end)
      ]

    Enum.map(schemas, fn entry ->
      Map.merge(entry, migration_versions(entry.schema))
    end)
  end

  defp migration_versions(schema) when is_binary(schema) do
    if Regex.match?(~r/^[a-z][a-z0-9_]*$/, schema) do
      sql = ~s(SELECT version FROM "#{schema}"."schema_migrations" ORDER BY version)

      case Ecto.Adapters.SQL.query(Repo, sql, []) do
        {:ok, %{rows: rows}} -> %{status: "ok", versions: Enum.map(rows, &List.first/1)}
        {:error, _reason} -> %{status: "unavailable", versions: []}
      end
    else
      %{status: "invalid_schema", versions: []}
    end
  end

  defp platform_version do
    case Application.spec(:contexla, :vsn) do
      nil -> "unknown"
      version -> to_string(version)
    end
  end

  defp filename(datetime),
    do: "contexla-support-#{Calendar.strftime(datetime, "%Y%m%d-%H%M%S")}.zip"

  defp encode(value), do: Jason.encode!(value, pretty: true)
  defp sha256(value), do: value |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
end
