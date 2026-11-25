defmodule Contexla.Platform.Test.Test.Web.ErrorJSONTest do
  use Contexla.Platform.Test.Support.ConnCase, async: true

  test "renders 404" do
    assert Contexla.Platform.Web.ErrorJSON.render("404.json", %{}) == %{
             errors: %{detail: "Not Found"}
           }
  end

  test "renders 500" do
    assert Contexla.Platform.Web.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
