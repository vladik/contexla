defmodule Contexla.AuditEvents do
  @moduledoc "Append-only audit records for current platform lifecycle actions."

  import Ecto.Query, warn: false

  alias Contexla.Accounts.{Scope, User}
  alias Contexla.AuditEvents.Event
  alias Contexla.Repo

  @spec record(Scope.t(), map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def record(%Scope{user: %User{} = user}, attrs) when is_map(attrs) do
    attrs = Map.put(attrs, :actor_user_id, user.id)

    %Event{}
    |> Event.create_changeset(attrs)
    |> Repo.insert()
  end

  @spec list_for_instance(Scope.t(), Ecto.UUID.t()) :: [Event.t()]
  def list_for_instance(%Scope{user: %User{}}, instance_id) do
    Event
    |> where([event], event.application_instance_id == ^instance_id)
    |> order_by([event], desc: event.sequence)
    |> Repo.all()
  end
end
