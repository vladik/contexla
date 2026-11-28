defmodule Contexla.Applications.Sdk.Test.RuntimeTest do
  use ExUnit.Case, async: false

  alias Contexla.Applications.Sdk.Runtime

  defmodule FakeRepo do
  end

  defmodule FakePlatform do
    @behaviour Contexla.Applications.Sdk.PlatformServices

    @impl true
    def create_instance(actor_id, attrs), do: {:created, actor_id, attrs}

    @impl true
    def get_instance(actor_id, instance_id), do: {:instance, actor_id, instance_id}

    @impl true
    def update_instance_config(actor_id, instance_id, config),
      do: {:updated, actor_id, instance_id, config}

    @impl true
    def get_artifact(actor_id, artifact_id), do: {:artifact, actor_id, artifact_id}

    @impl true
    def list_artifacts(actor_id, instance_id), do: [{actor_id, instance_id}]

    @impl true
    def import_source(actor_id, instance_id, adapter_id, path, options),
      do: {:imported, actor_id, instance_id, adapter_id, path, options}

    @impl true
    def artifact_path(artifact), do: {:path, artifact}

    @impl true
    def fetch_adapter(adapter_id), do: {:adapter, adapter_id}

    @impl true
    def invoke_operation(actor_id, instance_id, operation_id, input, options),
      do: {:operation, actor_id, instance_id, operation_id, input, options}

    @impl true
    def enqueue(worker, args, options), do: {:job, worker, args, options}

    @impl true
    def gateway_fetch(connection_id, path_template, entity_ref),
      do: {:gateway, connection_id, path_template, entity_ref}

    @impl true
    def list_connections, do: []
  end

  setup do
    previous = Application.get_env(:contexla_application_sdk, :services)

    Application.put_env(:contexla_application_sdk, :services, %{
      platform: FakePlatform,
      repo: FakeRepo
    })

    on_exit(fn ->
      if previous do
        Application.put_env(:contexla_application_sdk, :services, previous)
      else
        Application.delete_env(:contexla_application_sdk, :services)
      end
    end)
  end

  test "exposes named runtime services without dynamic platform calls" do
    assert Runtime.repo!() == FakeRepo

    assert Runtime.create_instance("actor", %{"name" => "Example"}) ==
             {:created, "actor", %{"name" => "Example"}}

    assert Runtime.get_instance("actor", "instance") ==
             {:instance, "actor", "instance"}

    assert Runtime.update_instance_config("actor", "instance", %{"mode" => "safe"}) ==
             {:updated, "actor", "instance", %{"mode" => "safe"}}

    assert Runtime.get_artifact("actor", "artifact") ==
             {:artifact, "actor", "artifact"}

    assert Runtime.list_artifacts("actor", "instance") == [{"actor", "instance"}]

    assert Runtime.import_source("actor", "instance", "adapter", "snapshot.zip",
             filename: "snapshot.zip"
           ) ==
             {:imported, "actor", "instance", "adapter", "snapshot.zip",
              [filename: "snapshot.zip"]}

    assert Runtime.artifact_path(:artifact) == {:path, :artifact}
    assert Runtime.fetch_adapter("adapter") == {:adapter, "adapter"}

    assert Runtime.invoke_operation("actor", "instance", "operation", %{}, approved: true) ==
             {:operation, "actor", "instance", "operation", %{}, [approved: true]}

    assert Runtime.enqueue(__MODULE__, %{"id" => "run"}, schedule_in: 1) ==
             {:job, __MODULE__, %{"id" => "run"}, [schedule_in: 1]}
  end

  test "raises clearly when the host omitted a required service" do
    Application.put_env(:contexla_application_sdk, :services, %{repo: FakeRepo})

    assert_raise KeyError, fn ->
      Runtime.get_instance("actor", "instance")
    end
  end
end
