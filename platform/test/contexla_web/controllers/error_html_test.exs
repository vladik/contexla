defmodule ContexlaWeb.ErrorHTMLTest do
  use ContexlaWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    html = render_to_string(ContexlaWeb.ErrorHTML, "404", "html", [])
    assert html =~ "Page not found"
    assert html =~ "Return home"
  end

  test "renders 500.html" do
    html = render_to_string(ContexlaWeb.ErrorHTML, "500", "html", [])
    assert html =~ "Something went wrong"
    assert html =~ "Return home"
  end
end
