defmodule Contexla.Platform.Gateway.Adapters.Csv do
  @moduledoc "Fetches a CSV file URL and parses rows into a list of maps keyed by header."

  @behaviour Contexla.Platform.Gateway.Adapter

  @max_bytes 10 * 1024 * 1024

  @impl true
  def label, do: "CSV file"

  @impl true
  def connection_fields do
    [
      %{key: :auth_type, label: "Authentication", type: :select, secret: false,
        options: [
          {"None", "none"},
          {"Bearer token", "bearer"},
          {"Basic auth", "basic"}
        ],
        show_when: nil},
      %{key: :token, label: "Token", type: :password, secret: true, options: nil,
        show_when: {:auth_type, "bearer"}},
      %{key: :username, label: "Username", type: :text, secret: false, options: nil,
        show_when: {:auth_type, "basic"}},
      %{key: :password, label: "Password", type: :password, secret: true, options: nil,
        show_when: {:auth_type, "basic"}}
    ]
  end

  @impl true
  def fetch(url, connection) do
    options =
      [url: url, retry: false, receive_timeout: 30_000, decode_body: false]
      |> Keyword.merge(auth_options(connection.credentials))
      |> Keyword.merge(Application.get_env(:contexla, :req_options, []))

    case Req.get(options) do
      {:ok, %Req.Response{status: status, body: body}}
      when status in 200..299 and is_binary(body) and byte_size(body) <= @max_bytes ->
        case parse_csv(body) do
          {:ok, rows} ->
            {:ok,
             %{
               document: rows,
               body: body,
               status: status,
               media_type: "text/csv",
               sha256: body |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower),
               excerpt: String.slice(body, 0, 2_000),
               fetched_at: DateTime.utc_now(:second)
             }}

          {:error, reason} ->
            {:error, {:csv_parse_error, reason}}
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

  defp auth_options(_), do: []

  defp parse_csv(body) do
    lines =
      body
      |> String.split(~r/\r?\n/)
      |> Enum.reject(&(String.trim(&1) == ""))

    case lines do
      [] ->
        {:ok, []}

      [header_line | data_lines] ->
        headers = split_csv_line(header_line)

        rows =
          Enum.map(data_lines, fn line ->
            values = split_csv_line(line)
            headers |> Enum.zip(values) |> Map.new()
          end)

        {:ok, rows}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp split_csv_line(line) do
    line
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&strip_quotes/1)
  end

  defp strip_quotes(<<"\"", rest::binary>>) do
    case String.split(rest, "\"", parts: 2) do
      [value, _] -> value
      _ -> rest
    end
  end

  defp strip_quotes(value), do: value
end
