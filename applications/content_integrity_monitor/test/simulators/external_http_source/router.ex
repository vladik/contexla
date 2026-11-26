defmodule Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource.Router do
  @moduledoc false

  use Plug.Router

  alias Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource.State

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  @programs %{
    "PN100" => %{name: "Practical Nursing", credential: "Ontario College Advanced Diploma", duration: "3 years"},
    "PN101" => %{name: "Computer Programming", credential: "Ontario College Diploma", duration: "2 years"},
    "PN102" => %{name: "Business Administration", credential: "Ontario College Certificate", duration: "1 year"}
  }

  get "/scope/programs" do
    ids = @programs |> Map.keys() |> Enum.sort() |> Enum.map(&%{"id" => &1})
    json(conn, %{"programs" => ids})
  end

  get "/authority/programs/:id" do
    id = conn.params["id"]
    json(conn, program_json(id, credential(id), duration(id), updated_at()))
  end

  get "/delivery/programs/:id" do
    id = conn.params["id"]
    json(conn, program_json(id, credential(id), duration(id), updated_at()))
  end

  get "/programs/:id" do
    id = conn.params["id"]

    displayed_credential =
      if State.mode() == :healthy, do: credential(id), else: "WRONG CREDENTIAL"

    html(conn, program_html(id, displayed_credential, duration(id), updated_at()))
  end

  get "/search/programs/:id" do
    id = conn.params["id"]

    cond do
      State.mode() == :unavailable ->
        Plug.Conn.send_resp(conn, 503, "search unavailable")

      State.mode() == :healthy ->
        html(conn, program_html(id, credential(id), duration(id), updated_at()))

      true ->
        html(conn, program_html(id, credential(id), nil, updated_at()))
    end
  end

  get "/status" do
    json(conn, %{"mode" => to_string(State.mode())})
  end

  post "/mode/:mode" when mode in ["healthy", "pending", "overdue", "unavailable"] do
    :ok = State.set_mode(String.to_existing_atom(mode))
    json(conn, %{"mode" => mode})
  end

  match _ do
    Plug.Conn.send_resp(conn, 404, "not found")
  end

  defp credential(id), do: get_in(@programs, [id, :credential]) || "Ontario College Certificate"
  defp duration(id), do: get_in(@programs, [id, :duration]) || "1 year"
  defp name(id), do: get_in(@programs, [id, :name]) || "Unknown Program"

  defp program_json(id, credential, duration, updated_at) do
    %{
      "program" => %{
        "id" => id,
        "name" => name(id),
        "credential" => credential,
        "duration" => duration,
        "updated_at" => updated_at
      }
    }
  end

  defp program_html(id, credential, duration, updated_at) do
    """
    <!doctype html>
    <html><body><article data-program-id="#{id}">
      <h1 data-field="program-name">#{name(id)}</h1>
      <p data-field="credential">#{credential}</p>
      #{if duration, do: ~s(<p data-field="duration">#{duration}</p>), else: ""}
      <time data-field="updated-at">#{updated_at}</time>
    </article></body></html>
    """
  end

  defp updated_at do
    offset = if State.mode() == :pending, do: 0, else: -4 * 60 * 60

    DateTime.utc_now(:second)
    |> DateTime.add(offset, :second)
    |> DateTime.to_iso8601()
  end

  defp json(conn, value) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, Jason.encode!(value))
  end

  defp html(conn, value) do
    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, value)
  end
end
