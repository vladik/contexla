defmodule Contexla.Platform.Web.PageController do
  use Contexla.Platform.Web, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
