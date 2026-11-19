defmodule ContexlaWeb.ApplicationSurfaceControllerTest do
  use ContexlaWeb.ConnCase, async: true

  alias Contexla.Applications
  import Contexla.AccountsFixtures

  test "mounts an installed Application surface behind a stable platform route", %{conn: conn} do
    user = user_fixture()
    scope = Contexla.Accounts.Scope.for_user(user)

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Dynamically mounted test",
        "config" => %{}
      })

    conn = conn |> log_in_user(user) |> get("/applications/#{instance.id}/overview")

    assert html_response(conn, 200) =~ "test-application-surface"
    assert html_response(conn, 200) =~ "Dynamically mounted test"
  end

  test "passes route query values through the dynamic surface session", %{conn: conn} do
    user = user_fixture()
    scope = Contexla.Accounts.Scope.for_user(user)

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Surface parameters",
        "config" => %{}
      })

    conn =
      conn
      |> log_in_user(user)
      |> get("/applications/#{instance.id}/overview?run_id=run-123")

    assert html_response(conn, 200) =~ ~s(data-run-id="run-123")
  end
end
