defmodule ContexlaWeb.ApplicationOperationControllerTest do
  use ContexlaWeb.ConnCase, async: true

  alias Contexla.Applications
  import Contexla.AccountsFixtures

  setup %{conn: conn} do
    user = user_fixture()
    scope = Contexla.Accounts.Scope.for_user(user)

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "HTTP Operation Instance",
        "config" => %{}
      })

    %{conn: log_in_user(conn, user), instance: instance, user: user}
  end

  test "uses POST for command Operations", %{conn: conn, instance: instance} do
    response =
      conn
      |> post("/application-operations/#{instance.id}/test.echo", %{"message" => "hello"})
      |> json_response(200)

    assert response["data"] == %{"echo" => "hello"}
    assert is_binary(response["invocation_id"])
  end

  test "rejects command execution over GET", %{conn: conn, instance: instance} do
    response =
      conn
      |> get("/application-operations/#{instance.id}/test.echo?message=hello")
      |> json_response(405)

    assert response["error"]["code"] == "operation_requires_post"
  end

  test "requires and records explicit approval", %{conn: conn, instance: instance, user: user} do
    response =
      conn
      |> post("/application-operations/#{instance.id}/test.approved", %{})
      |> json_response(409)

    assert response["error"]["code"] == "approval_required"

    approved =
      build_conn()
      |> log_in_user(user)
      |> post("/application-operations/#{instance.id}/test.approved", %{
        "approval" => "approved"
      })
      |> json_response(200)

    assert approved["data"] == %{"approved" => true}
  end

  test "allows declared read downloads over GET", %{conn: conn, instance: instance} do
    conn = get(conn, "/application-operations/#{instance.id}/test.download")

    assert response(conn, 200) == "downloaded"
    assert [invocation_id] = get_resp_header(conn, "x-contexla-invocation-id")
    assert is_binary(invocation_id)
  end

  test "does not expose internal reasons for undeclared Operations", %{
    conn: conn,
    instance: instance
  } do
    response =
      conn
      |> post("/application-operations/#{instance.id}/not.declared", %{})
      |> json_response(404)

    assert response == %{
             "error" => %{
               "code" => "operation_not_declared",
               "invocation_id" => nil,
               "message" => "The Application does not declare this Operation."
             }
           }
  end
end
