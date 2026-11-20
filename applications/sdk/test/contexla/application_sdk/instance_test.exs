defmodule Contexla.ApplicationSDK.InstanceTest do
  use ExUnit.Case, async: true

  alias Contexla.ApplicationSDK.Instance

  test "builds an Instance from a platform surface session without dynamic atoms" do
    session = %{
      "id" => "instance-1",
      "application_id" => "com.contexla.test",
      "application_version" => "1.0.0",
      "name" => "Test estate",
      "status" => "draft",
      "config" => %{"scope" => "test"},
      "actor_id" => "user-1"
    }

    assert %Instance{
             id: "instance-1",
             application_id: "com.contexla.test",
             actor_id: "user-1",
             status: "draft"
           } = Instance.from_session!(session)
  end

  test "rejects incomplete session data" do
    assert_raise ArgumentError, fn -> Instance.from_session!(%{"id" => "incomplete"}) end
  end
end
