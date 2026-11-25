defmodule Contexla.Platform.Test.Test.Web.ApplicationSurfaceControllerTest do
  use Contexla.Platform.Test.Support.ConnCase, async: true

  alias Contexla.Platform.Applications
  import Contexla.Platform.Test.Support.Fixtures.AccountsFixtures

  test "mounts an installed Application surface behind a stable platform route", %{conn: conn} do
    user = user_fixture()
    scope = Contexla.Platform.Accounts.Scope.for_user(user)

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Dynamically mounted test",
        "config" => %{}
      })

    conn = conn |> log_in_user(user) |> get("/applications/#{instance.id}")

    assert html_response(conn, 200) =~ "test-application-surface"
    assert html_response(conn, 200) =~ "Dynamically mounted test"
    assert html_response(conn, 200) =~ ~s(id="contexla-platform-shell")
    assert html_response(conn, 200) =~ ~s(data-tooltip="Dynamically mounted test")
    assert html_response(conn, 200) =~ ~s(id="agent-workspace")
    assert html_response(conn, 200) =~ "Application Instance"
    assert html_response(conn, 200) =~ "Application overview"
  end

  test "passes route query values through the dynamic surface session", %{conn: conn} do
    user = user_fixture()
    scope = Contexla.Platform.Accounts.Scope.for_user(user)

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Surface parameters",
        "config" => %{}
      })

    conn =
      conn
      |> log_in_user(user)
      |> get("/applications/#{instance.id}?run_id=run-123")

    assert html_response(conn, 200) =~ ~s(data-run-id="run-123")
  end

  test "keeps explicitly named Instance surfaces available", %{conn: conn} do
    user = user_fixture()
    scope = Contexla.Platform.Accounts.Scope.for_user(user)

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Named surface",
        "config" => %{}
      })

    conn = conn |> log_in_user(user) |> get("/applications/#{instance.id}/overview")

    assert html_response(conn, 200) =~ "Named surface"
  end

  test "renders platform and Application settings surfaces for an Instance", %{conn: conn} do
    user = user_fixture()
    scope = Contexla.Platform.Accounts.Scope.for_user(user)

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Configurable Instance",
        "config" => %{}
      })

    general = conn |> log_in_user(user) |> get("/applications/#{instance.id}/settings")
    general_html = html_response(general, 200)
    assert general_html =~ "Instance settings"
    assert general_html =~ "Choose Instance icon"
    assert general_html =~ "/applications/#{instance.id}/configuration"

    application =
      build_conn() |> log_in_user(user) |> get("/applications/#{instance.id}/configuration")

    assert html_response(application, 200) =~ ~s(id="test-settings-surface")
  end
end
