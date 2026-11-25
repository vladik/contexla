defmodule Contexla.Platform.Web.SupportBundleController do
  use Contexla.Platform.Web, :controller

  alias Contexla.Platform.SupportBundles

  def download(conn, _params) do
    case SupportBundles.generate(conn.assigns.current_scope) do
      {:ok, bundle} ->
        conn
        |> put_resp_header("x-contexla-support-bundle-id", bundle.id)
        |> put_resp_header("x-contexla-content-sha256", bundle.sha256)
        |> send_download({:binary, bundle.contents},
          filename: bundle.filename,
          content_type: bundle.content_type
        )

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: %{code: "forbidden"}})

      {:error, _reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{error: %{code: "support_bundle_unavailable"}})
    end
  end
end
