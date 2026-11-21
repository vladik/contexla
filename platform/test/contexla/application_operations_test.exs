defmodule Contexla.ApplicationOperationsTest do
  use Contexla.DataCase, async: false

  alias Contexla.ApplicationOperations
  alias Contexla.ApplicationOperations.Invocation
  alias Contexla.Applications

  import Contexla.AccountsFixtures

  setup do
    scope = user_scope_fixture()

    {:ok, instance} =
      Applications.create_instance(scope, %{
        "application_id" => "com.contexla.test.application",
        "name" => "Operation Instance",
        "config" => %{}
      })

    %{scope: scope, instance: instance}
  end

  test "invokes only a declared Operation and records bounded audit data", context do
    assert {:ok, %{"echo" => "hello"}, invocation} =
             ApplicationOperations.invoke(
               context.scope,
               context.instance.id,
               "test.echo",
               %{"message" => "hello"}
             )

    assert invocation.status == :succeeded
    assert invocation.input == %{"message" => "hello"}
    assert invocation.output == %{"type" => "result"}
    assert invocation.application_version == "1.0.0"
    assert Repo.get!(Invocation, invocation.id).completed_at
  end

  test "rejects undeclared Operations without creating an invocation", context do
    assert {:error, :operation_not_declared} =
             ApplicationOperations.invoke(
               context.scope,
               context.instance.id,
               "test.unknown",
               %{}
             )

    refute Repo.exists?(Invocation)
  end

  test "validates input and rejects undeclared fields", context do
    assert {:error, %{path: "$", unexpected: ["extra"]}} =
             ApplicationOperations.invoke(
               context.scope,
               context.instance.id,
               "test.echo",
               %{"message" => "hello", "extra" => "not declared"}
             )

    refute Repo.exists?(Invocation)
  end

  test "requires explicit approval and records the authenticated approver", context do
    assert {:error, {:approval_required, "test.approved"}} =
             ApplicationOperations.invoke(
               context.scope,
               context.instance.id,
               "test.approved",
               %{}
             )

    refute Repo.exists?(Invocation)

    assert {:ok, %{"approved" => true}, invocation} =
             ApplicationOperations.invoke(
               context.scope,
               context.instance.id,
               "test.approved",
               %{},
               approved: true
             )

    assert invocation.approval_required
    assert invocation.approved_by_user_id == context.scope.user.id
    assert invocation.approved_at
  end

  test "allows GET-style transport only for declared read Operations", context do
    assert {:error, :operation_requires_post} =
             ApplicationOperations.invoke(
               context.scope,
               context.instance.id,
               "test.echo",
               %{"message" => "hello"},
               transport: :read
             )

    assert {:download, "downloaded", _options, invocation} =
             ApplicationOperations.invoke(
               context.scope,
               context.instance.id,
               "test.download",
               %{},
               transport: :read
             )

    assert invocation.output["type"] == "download"
  end

  test "preflights required Capabilities before creating an invocation", context do
    assert {:error,
            {:required_capability_unavailable, "com.contexla.missing", "1", :capability_not_found}} =
             ApplicationOperations.invoke(
               context.scope,
               context.instance.id,
               "test.missing-capability",
               %{}
             )

    refute Repo.exists?(Invocation)
  end

  test "records a normalized failure without persisting arbitrary error details", context do
    assert {:error, :expected_failure, invocation} =
             ApplicationOperations.invoke(
               context.scope,
               context.instance.id,
               "test.failure",
               %{}
             )

    assert invocation.status == :failed
    assert invocation.error == %{"code" => "expected_failure"}
  end
end
