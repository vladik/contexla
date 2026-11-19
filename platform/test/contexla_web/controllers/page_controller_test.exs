defmodule ContexlaWeb.PageControllerTest do
  use ContexlaWeb.ConnCase, async: true

  import Contexla.AccountsFixtures

  test "redirects an anonymous user to login", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log-in"
  end

  test "renders the platform for an authenticated user", %{conn: conn} do
    user = user_fixture()

    conn = conn |> log_in_user(user) |> get(~p"/")

    assert html_response(conn, 200) =~ "Applications"
  end

  test "redirects a bootstrap-password user to settings", %{conn: conn} do
    user = user_fixture()

    user =
      user
      |> Ecto.Changeset.change(must_change_password: true)
      |> Contexla.Repo.update!()

    conn = conn |> log_in_user(user) |> get(~p"/")

    assert redirected_to(conn) == ~p"/users/settings"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "bootstrap password"
  end

  test "does not expose public registration", %{conn: conn} do
    refute html_response(get(conn, "/users/register"), 404) =~ "Sign up"
  end
end
