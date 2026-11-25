defmodule Contexla.Platform.Test.Support.PackageFixtures.TestApplication do
  @behaviour Contexla.Applications.Sdk.Application

  alias Contexla.Applications.Sdk.{Definition, Operation, Surface}
  alias Contexla.Tools.Sdk.Requirement

  @operations [
    %Operation{
      id: "test.echo",
      name: "Echo",
      input_schema: %{
        "type" => "object",
        "required" => ["message"],
        "additionalProperties" => false,
        "properties" => %{"message" => %{"type" => "string"}}
      }
    },
    %Operation{
      id: "test.approved",
      name: "Approved command",
      requires_approval: true
    },
    %Operation{id: "test.download", name: "Download", kind: :read},
    %Operation{id: "test.failure", name: "Failure"},
    %Operation{
      id: "test.missing-tool",
      name: "Missing Tool",
      required_tools: [
        %Requirement{tool_id: "com.contexla.missing", version: "1.0.0"}
      ]
    }
  ]

  @impl true
  def definition do
    %Definition{
      id: "com.contexla.test.application",
      name: "Test Application",
      icon: "hero-beaker",
      version: "1.0.0",
      otp_application: :contexla,
      entry_module: __MODULE__,
      config_schema: %{},
      operations: available_operations(),
      surfaces: [
        %Surface{
          id: :new,
          path: "new",
          module: Contexla.Platform.Test.Support.PackageFixtures.TestNewSurfaceLive,
          role: :new,
          label: "New test"
        },
        %Surface{
          id: :overview,
          path: "overview",
          module: Contexla.Platform.Test.Support.PackageFixtures.TestSurfaceLive,
          role: :instance,
          default: true,
          label: "Test overview"
        },
        %Surface{
          id: :settings,
          path: "configuration",
          module: Contexla.Platform.Test.Support.PackageFixtures.TestSettingsSurfaceLive,
          role: :instance,
          kind: :settings,
          label: "Test settings"
        }
      ],
      required_adapter_contracts: ["contexla.test.source.v1"]
    }
  end

  @impl true
  def validate_instance_config(config) when is_map(config), do: {:ok, config}
  def validate_instance_config(_config), do: {:error, :invalid_config}

  @impl true
  def available_operations, do: @operations

  @impl true
  def required_adapter_contracts, do: ["contexla.test.source.v1"]

  @impl true
  def execute_operation("test.echo", _instance, %{"message" => message}) do
    {:ok, %{"echo" => message}}
  end

  def execute_operation("test.approved", _instance, _input) do
    {:ok, %{"approved" => true}}
  end

  def execute_operation("test.download", _instance, _input) do
    {:download, "downloaded", filename: "test.txt", content_type: "text/plain"}
  end

  def execute_operation("test.failure", _instance, _input), do: {:error, :expected_failure}

  def execute_operation("test.missing-tool", _instance, _input) do
    raise "unavailable Tool should prevent execution"
  end
end

defmodule Contexla.Platform.Test.Support.PackageFixtures.TestSettingsSurfaceLive do
  use Phoenix.LiveView

  @impl true
  def mount(_params, %{"instance" => instance}, socket) do
    {:ok, Phoenix.Component.assign(socket, :instance, instance)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="test-settings-surface">{@instance["name"]}</div>
    """
  end
end

defmodule Contexla.Platform.Test.Support.PackageFixtures.TestNewSurfaceLive do
  use Phoenix.LiveView

  @impl true
  def mount(_params, session, socket) do
    {:ok, Phoenix.Component.assign(socket, :application_id, session["application_id"])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="test-new-application-surface">{@application_id}</div>
    """
  end
end

defmodule Contexla.Platform.Test.Support.PackageFixtures.TestSurfaceLive do
  use Phoenix.LiveView

  @impl true
  def mount(_params, %{"instance" => instance, "surface_params" => surface_params}, socket) do
    {:ok,
     socket
     |> Phoenix.Component.assign(:instance, instance)
     |> Phoenix.Component.assign(:surface_params, surface_params)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="test-application-surface" data-run-id={@surface_params["run_id"]}>
      {@instance["name"]}
    </div>
    """
  end
end

defmodule Contexla.Platform.Test.Support.PackageFixtures.TestAdapter do
  def validate_source(path, _options) do
    with {:ok, bytes} <- File.read(path) do
      {:ok,
       %{
         sha256: Base.encode16(:crypto.hash(:sha256, bytes), case: :lower),
         byte_size: byte_size(bytes),
         source_type: "contexla.test-source.v1",
         manifest: %{"name" => Path.basename(path)},
         files: []
       }}
    end
  end
end

defmodule Contexla.Platform.Test.Support.PackageFixtures.TestIntegration do
  alias Contexla.Integrations.Sdk.{Adapter, Definition}

  def definition do
    %Definition{
      id: "com.contexla.test.integration",
      name: "Test Integration",
      version: "1.0.0",
      otp_application: :contexla,
      entry_module: __MODULE__,
      adapters: [
        %Adapter{
          id: "test.snapshot.v1",
          contract: "contexla.test.source.v1",
          module: Contexla.Platform.Test.Support.PackageFixtures.TestAdapter,
          source_types: ["file"]
        }
      ]
    }
  end
end
