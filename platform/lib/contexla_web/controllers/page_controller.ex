defmodule ContexlaWeb.PageController do
  use ContexlaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
