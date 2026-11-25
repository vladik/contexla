defmodule Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource.Router do
  @moduledoc false

  use Plug.Router

  alias Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource.State

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/authority/programs/PN123" do
    json(conn, program("Ontario College Diploma", "2 years", updated_at()))
  end

  get "/delivery/programs/PN123" do
    json(conn, program("Ontario College Diploma", "2 years", updated_at()))
  end

  get "/programs/PN123" do
    html(conn, program_html("Ontario College Certificate", "2 years", updated_at()))
  end

  get "/search/programs/PN123" do
    if State.mode() == :unavailable do
      Plug.Conn.send_resp(conn, 503, "search unavailable")
    else
      html(conn, program_html("Ontario College Diploma", nil, updated_at()))
    end
  end

  get "/status" do
    json(conn, %{"mode" => to_string(State.mode())})
  end

  post "/mode/:mode" when mode in ["pending", "overdue", "unavailable"] do
    :ok = State.set_mode(String.to_existing_atom(mode))
    json(conn, %{"mode" => mode})
  end

  match _ do
    Plug.Conn.send_resp(conn, 404, "not found")
  end

  defp program(credential, duration, updated_at) do
    %{
      "program" => %{
        "id" => "PN123",
        "name" => "Practical Nursing",
        "credential" => credential,
        "duration" => duration,
        "updated_at" => updated_at
      }
    }
  end

  defp program_html(credential, duration, updated_at) do
    """
    <!doctype html>
    <html><body><article data-program-id="PN123">
      <h1 data-field="program-name">Practical Nursing</h1>
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
