defmodule ContexlaWeb.SupportBundleControllerTest do
  use ContexlaWeb.ConnCase, async: false

  import Contexla.AccountsFixtures

  test "an administrator downloads an in-memory support bundle", %{conn: conn} do
    conn = conn |> log_in_user(admin_fixture()) |> get(~p"/operations/support-bundle")

    body = response(conn, 200)
    assert get_resp_header(conn, "content-type") == ["application/zip"]
    assert [bundle_id] = get_resp_header(conn, "x-contexla-support-bundle-id")
    assert {:ok, _bundle_id} = Ecto.UUID.cast(bundle_id)
    assert [sha256] = get_resp_header(conn, "x-contexla-content-sha256")
    assert byte_size(sha256) == 64
    assert {:ok, entries} = :zip.extract(body, [:memory])
    assert {~c"manifest.json", _contents} = List.keyfind(entries, ~c"manifest.json", 0)
  end

  test "a regular user is redirected before bundle generation", %{conn: conn} do
    conn = conn |> log_in_user(user_fixture()) |> get(~p"/operations/support-bundle")
    assert redirected_to(conn) == ~p"/"
  end
end
