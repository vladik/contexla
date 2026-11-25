defmodule Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSourceTest do
  use ExUnit.Case, async: false

  alias Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource

  setup do
    start_supervised!({ExternalHttpSource, port: 0})
    :ok
  end

  test "serves the deterministic source status" do
    conn =
      :get
      |> Plug.Test.conn("/status")
      |> ExternalHttpSource.Router.call([])

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{"mode" => "overdue"}
  end
end
