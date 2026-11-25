defmodule Contexla.Platform.Test.Test.Web.HealthControllerTest do
  use Contexla.Platform.Test.Support.ConnCase, async: false

  setup do
    path = Application.fetch_env!(:contexla, :artifact_storage_path)
    File.mkdir_p!(path)
    :ok
  end

  test "liveness is public and process-local", %{conn: conn} do
    conn = get(conn, ~p"/health/live")
    assert json_response(conn, 200) == %{"status" => "ok"}
  end

  test "readiness checks current platform dependencies", %{conn: conn} do
    conn = get(conn, ~p"/health/ready")

    assert %{
             "status" => "ok",
             "checks" => %{
               "artifact_storage" => "ok",
               "tool_registry" => "ok",
               "database" => "ok",
               "oban" => "ok",
               "package_registry" => "ok"
             }
           } = json_response(conn, 200)
  end
end
