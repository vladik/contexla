defmodule Contexla.Platform.Web.HealthController do
  use Contexla.Platform.Web, :controller

  def live(conn, _params), do: json(conn, %{status: "ok"})

  def ready(conn, _params) do
    result = Contexla.Platform.Diagnostics.check()
    status = if result.status == :ok, do: 200, else: 503

    conn
    |> put_status(status)
    |> json(%{
      status: Atom.to_string(result.status),
      checks: Map.new(result.checks, fn {name, value} -> {name, Atom.to_string(value)} end)
    })
  end
end
