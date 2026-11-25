defmodule Contexla.Applications.ContentIntegrityMonitor.Test.SourceClientTest do
  use ExUnit.Case, async: false

  alias Contexla.Applications.ContentIntegrityMonitor.{Source, SourceClient}

  setup do
    previous = Application.get_env(:content_integrity_monitor, :req_options)
    Application.put_env(:content_integrity_monitor, :req_options, plug: {Req.Test, __MODULE__})

    on_exit(fn ->
      if previous,
        do: Application.put_env(:content_integrity_monitor, :req_options, previous),
        else: Application.delete_env(:content_integrity_monitor, :req_options)
    end)
  end

  test "acquires and decodes a bounded JSON Source" do
    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.json(conn, %{
        "program" => %{
          "name" => "Practical Nursing",
          "credential" => "Diploma",
          "duration" => "2 years"
        }
      })
    end)

    source = %Source{format: :json, url: "http://integrity.test/programs/PN123"}

    assert {:ok, result} = SourceClient.fetch(source)
    assert result.status == 200
    assert result.document["program"]["credential"] == "Diploma"
    assert result.media_type == "application/json"
    assert result.sha256 =~ ~r/^[0-9a-f]{64}$/
  end

  test "returns a bounded error for an unavailable response" do
    Req.Test.stub(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 503, "unavailable") end)

    assert {:error, {:source_http_status, 503}} =
             SourceClient.fetch(%Source{format: :html, url: "http://integrity.test/page"})
  end
end
