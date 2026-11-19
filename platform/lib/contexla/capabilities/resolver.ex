defmodule Contexla.Capabilities.Resolver do
  @moduledoc "Resolves the most specific active Processor binding for an invocation."

  import Ecto.Query, warn: false

  alias Contexla.Applications.ApplicationInstance
  alias Contexla.Capabilities.{Binding, Contract, Processor}
  alias Contexla.Repo

  def resolve(%Contract{} = contract, %ApplicationInstance{} = instance) do
    [
      {:instance, instance.id},
      {:application, instance.application_id},
      {:platform, "platform"}
    ]
    |> Enum.find_value(&binding(contract, &1))
    |> result()
  end

  def resolve(%Contract{} = contract, nil) do
    contract
    |> binding({:platform, "platform"})
    |> result()
  end

  defp binding(contract, {scope, scope_key}) do
    from(binding in Binding,
      join: processor in assoc(binding, :processor),
      where:
        binding.capability_id == ^contract.id and binding.scope == ^scope and
          binding.scope_key == ^to_string(scope_key) and binding.status == :active and
          processor.status == :active,
      preload: [processor: processor]
    )
    |> Repo.one()
  end

  defp result(nil), do: {:error, :capability_not_bound}

  defp result(%Binding{processor: %Processor{} = processor} = binding) do
    if MapSet.subset?(
         MapSet.new(processor.requested_permissions),
         MapSet.new(binding.granted_permissions)
       ) do
      {:ok, binding, processor}
    else
      {:error, :processor_permissions_not_granted}
    end
  end
end
