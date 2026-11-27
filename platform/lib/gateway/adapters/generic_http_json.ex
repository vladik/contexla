defmodule Contexla.Platform.Gateway.Adapters.GenericHttpJson do
  @moduledoc "Fetches a URL and decodes the response as JSON."

  @behaviour Contexla.Platform.Gateway.Adapter

  @max_bytes 4 * 1024 * 1024

  @impl true
  def label, do: "Generic REST API (JSON)"

  @impl true
  def connection_fields do
    [
      %{key: :auth_type, label: "Authentication", type: :select, secret: false,
        options: [
          {"None", "none"},
          {"Bearer token", "bearer"},
          {"Basic auth", "basic"},
          {"API key — header", "api_key_header"},
          {"API key — query param", "api_key_query"}
        ],
        show_when: nil},
      %{key: :token, label: "Token", type: :password, secret: true, options: nil,
        show_when: {:auth_type, "bearer"}},
      %{key: :username, label: "Username", type: :text, secret: false, options: nil,
        show_when: {:auth_type, "basic"}},
      %{key: :password, label: "Password", type: :password, secret: true, options: nil,
        show_when: {:auth_type, "basic"}},
      %{key: :header_name, label: "Header name", type: :text, secret: false, options: nil,
        show_when: {:auth_type, "api_key_header"}},
      %{key: :header_value, label: "Header value", type: :password, secret: true, options: nil,
        show_when: {:auth_type, "api_key_header"}},
      %{key: :param_name, label: "Parameter name", type: :text, secret: false, options: nil,
        show_when: {:auth_type, "api_key_query"}},
      %{key: :param_value, label: "Parameter value", type: :password, secret: true, options: nil,
        show_when: {:auth_type, "api_key_query"}}
    ]
  end

  @impl true
  def fetch(url, connection) do
    options =
      [url: url, retry: false, receive_timeout: 15_000, decode_body: false]
      |> Keyword.merge(auth_options(connection.credentials))
      |> Keyword.merge(Application.get_env(:contexla, :req_options, []))

    case Req.get(options) do
      {:ok, %Req.Response{status: status, body: body}}
      when status in 200..299 and is_binary(body) and byte_size(body) <= @max_bytes ->
        case Jason.decode(body) do
          {:ok, document} -> {:ok, build_result(document, body, status, "application/json")}
          _error -> {:error, :invalid_json_response}
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_status, status}}

      {:error, _reason} ->
        {:error, :connection_unavailable}
    end
  end

  defp auth_options(%{"auth_type" => "bearer", "token" => token}) do
    [headers: [{"authorization", "Bearer #{token}"}]]
  end

  defp auth_options(%{"auth_type" => "basic", "username" => username, "password" => password}) do
    encoded = Base.encode64("#{username}:#{password}")
    [headers: [{"authorization", "Basic #{encoded}"}]]
  end

  defp auth_options(%{"auth_type" => "api_key_header", "header_name" => name, "header_value" => value}) do
    [headers: [{name, value}]]
  end

  defp auth_options(%{"auth_type" => "api_key_query", "param_name" => name, "param_value" => value}) do
    [params: [{name, value}]]
  end

  defp auth_options(_), do: []

  defp build_result(document, body, status, media_type) do
    %{
      document: document,
      body: body,
      status: status,
      media_type: media_type,
      sha256: body |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower),
      excerpt: String.slice(body, 0, 2_000),
      fetched_at: DateTime.utc_now(:second)
    }
  end
end
