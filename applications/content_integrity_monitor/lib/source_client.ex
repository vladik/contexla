defmodule Contexla.Applications.ContentIntegrityMonitor.SourceClient do
  @moduledoc "Bounded HTTP acquisition for configured integrity Sources."

  @max_bytes 2 * 1024 * 1024

  def fetch(source) do
    options =
      [url: source.url, retry: false, receive_timeout: 10_000, decode_body: false]
      |> Keyword.merge(Application.get_env(:content_integrity_monitor, :req_options, []))

    case Req.get(options) do
      {:ok, %Req.Response{status: status, body: body} = response}
      when status in 200..299 and is_binary(body) and byte_size(body) <= @max_bytes ->
        decode(source.format, body, status, media_type(response))

      {:ok, %Req.Response{status: status}} ->
        {:error, {:source_http_status, status}}

      {:error, _reason} ->
        {:error, :source_unavailable}
    end
  end

  defp decode(:json, body, status, media_type) do
    case Jason.decode(body) do
      {:ok, document} when is_map(document) -> result(document, body, status, media_type)
      _error -> {:error, :invalid_json_source}
    end
  end

  defp decode(:html, body, status, media_type), do: result(body, body, status, media_type)

  defp result(document, body, status, media_type) do
    {:ok,
     %{
       document: document,
       status: status,
       media_type: media_type,
       sha256: body |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower),
       excerpt: String.slice(body, 0, 2_000),
       fetched_at: DateTime.utc_now(:second)
     }}
  end

  defp media_type(response) do
    response
    |> Req.Response.get_header("content-type")
    |> case do
      [] -> ["application/octet-stream"]
      values -> values
    end
    |> List.first()
    |> to_string()
    |> String.split(";", parts: 2)
    |> List.first()
  end
end
