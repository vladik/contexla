defmodule ContexlaWeb.OperationsLiveTest do
  use ContexlaWeb.ConnCase, async: false

  import Contexla.AccountsFixtures
  import Phoenix.LiveViewTest

  test "renders installation operations for an administrator", %{conn: conn} do
    conn = log_in_user(conn, admin_fixture())

    {:ok, view, html} = live(conn, ~p"/operations")

    assert html =~ "Installation health, execution activity, and support references"
    assert has_element?(view, "#operations-header")
    assert html =~ "System checks"
    assert html =~ "Application Operations"
    assert html =~ "Capability Invocations"
    assert html =~ "Background Jobs"
    assert html =~ "Audit Activity"
    assert has_element?(view, ~s(a[href="/operations/support-bundle"]), "Support bundle")
  end

  test "redirects a regular user", %{conn: conn} do
    conn = log_in_user(conn, user_fixture())

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/operations")
  end
end
