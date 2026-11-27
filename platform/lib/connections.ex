defmodule Contexla.Platform.Connections do
  import Ecto.Query

  alias Contexla.Platform.Repo
  alias Contexla.Platform.Connections.Connection

  def list_connections do
    Repo.all(from c in Connection, order_by: [asc: c.name])
  end

  def get_connection!(id), do: Repo.get!(Connection, id)

  def create_connection(attrs) do
    %Connection{}
    |> Connection.changeset(attrs)
    |> Repo.insert()
  end

  def update_connection(%Connection{} = connection, attrs) do
    connection
    |> Connection.changeset(attrs)
    |> Repo.update()
  end

  def delete_connection(%Connection{} = connection) do
    Repo.delete(connection)
  end

  def change_connection(%Connection{} = connection, attrs \\ %{}) do
    Connection.changeset(connection, attrs)
  end
end
