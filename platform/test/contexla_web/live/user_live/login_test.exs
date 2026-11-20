defmodule ContexlaWeb.UserLive.LoginTest do
  use ContexlaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "login page" do
    test "exposes password login without registration or magic link", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/users/log-in")

      assert has_element?(view, "#login_form_password")
      assert html =~ ~s(id="contexla-auth")
      refute html =~ ~s(id="contexla-platform-shell")
      refute has_element?(view, "#login_form_magic")
      refute has_element?(view, ~s(a[href="/users/register"]))
    end
  end
end
