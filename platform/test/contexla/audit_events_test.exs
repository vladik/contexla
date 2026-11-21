defmodule Contexla.AuditEventsTest do
  use Contexla.DataCase, async: true

  alias Contexla.AuditEvents
  alias Contexla.AuditEvents.Event
  alias Contexla.Repo

  import Contexla.AccountsFixtures

  test "records an actor-attributed append-only event" do
    scope = user_scope_fixture()

    assert {:ok, event} =
             AuditEvents.record(scope, %{
               action: "package.inspected",
               subject_type: "application_package",
               subject_id: "com.example.audit@1.0.0",
               metadata: %{"result" => "accepted"}
             })

    assert event.actor_user_id == scope.user.id
    assert event.metadata == %{"result" => "accepted"}
    assert Repo.get!(Event, event.id).action == "package.inspected"
  end

  test "rejects arbitrary action names" do
    scope = user_scope_fixture()

    assert {:error, changeset} =
             AuditEvents.record(scope, %{
               action: "Unsafe Action",
               subject_type: "test",
               subject_id: "1"
             })

    assert "has invalid format" in errors_on(changeset).action
  end
end
