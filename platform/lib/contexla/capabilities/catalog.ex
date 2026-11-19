defmodule Contexla.Capabilities.Catalog do
  @moduledoc """
  Synchronizes trusted code definitions into the queryable PostgreSQL catalog.

  Bundled package code is authoritative. An existing identity may only retain
  the same digest; changing a contract or Processor requires a new version.
  """

  alias Contexla.Capabilities.{Binding, Contract, Processor}
  alias Contexla.CapabilityRuntime.Registry
  alias Contexla.Repo

  @spec sync_bundled() :: :ok | {:error, term()}
  def sync_bundled do
    Repo.transaction(fn ->
      with :ok <- sync_capabilities(),
           :ok <- sync_processors(),
           :ok <- ensure_default_bindings() do
        :ok
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
    |> case do
      {:ok, :ok} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp sync_capabilities do
    Enum.reduce_while(Registry.capabilities(), :ok, fn definition, :ok ->
      attrs = capability_attrs(definition)

      case Repo.get_by(Contract,
             key: definition.id,
             contract_version: definition.contract_version
           ) do
        nil ->
          insert(Contract.changeset(%Contract{}, attrs))

        %Contract{definition_digest: digest} when digest == attrs.definition_digest ->
          {:cont, :ok}

        _contract ->
          {:halt,
           {:error, {:capability_definition_drift, definition.id, definition.contract_version}}}
      end
    end)
  end

  defp sync_processors do
    Enum.reduce_while(Registry.processors(), :ok, fn definition, :ok ->
      contract =
        Repo.get_by!(Contract,
          key: definition.capability_id,
          contract_version: definition.capability_contract_version
        )

      attrs = processor_attrs(definition, contract)

      case Repo.get_by(Processor, key: definition.id, version: definition.version) do
        nil ->
          insert(Processor.changeset(%Processor{}, attrs))

        %Processor{definition_digest: digest} when digest == attrs.definition_digest ->
          {:cont, :ok}

        _processor ->
          {:halt, {:error, {:processor_definition_drift, definition.id, definition.version}}}
      end
    end)
  end

  defp ensure_default_bindings do
    Registry.processors()
    |> Enum.filter(& &1.default)
    |> Enum.reduce_while(:ok, fn definition, :ok ->
      contract =
        Repo.get_by!(Contract,
          key: definition.capability_id,
          contract_version: definition.capability_contract_version
        )

      processor = Repo.get_by!(Processor, key: definition.id, version: definition.version)

      case Repo.get_by(Binding,
             capability_id: contract.id,
             scope: :platform,
             scope_key: "platform"
           ) do
        nil ->
          %Binding{}
          |> Binding.changeset(%{
            capability_id: contract.id,
            processor_id: processor.id,
            scope: :platform,
            scope_key: "platform",
            granted_permissions: definition.requested_permissions,
            config: %{},
            status: :active
          })
          |> insert()

        _binding ->
          {:cont, :ok}
      end
    end)
  end

  defp insert(changeset) do
    case Repo.insert(changeset) do
      {:ok, _record} -> {:cont, :ok}
      {:error, changeset} -> {:halt, {:error, changeset}}
    end
  end

  defp capability_attrs(definition) do
    definition
    |> Map.from_struct()
    |> Map.put(:key, definition.id)
    |> Map.delete(:id)
    |> Map.put(:definition_digest, digest(definition))
    |> Map.put(:status, :active)
  end

  defp processor_attrs(definition, contract) do
    definition
    |> Map.from_struct()
    |> Map.put(:key, definition.id)
    |> Map.delete(:id)
    |> Map.drop([:capability_id, :capability_contract_version, :default])
    |> Map.put(:capability_id, contract.id)
    |> Map.update!(:entrypoint, &entrypoint/1)
    |> Map.put(:definition_digest, digest(definition))
    |> Map.put(:status, :active)
  end

  defp entrypoint(value) when is_atom(value), do: Atom.to_string(value)
  defp entrypoint(value), do: value

  defp digest(definition) do
    definition
    |> Map.from_struct()
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
