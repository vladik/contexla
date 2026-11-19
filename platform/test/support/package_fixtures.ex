defmodule Contexla.TestApplication do
  @behaviour Contexla.ApplicationSDK.Application

  alias Contexla.ApplicationSDK.{Definition, Surface}

  @impl true
  def definition do
    %Definition{
      id: "com.contexla.test.application",
      name: "Test Application",
      version: "1.0.0",
      otp_application: :contexla,
      entry_module: __MODULE__,
      config_schema: %{},
      operations: [],
      surfaces: [
        %Surface{
          id: :overview,
          path: "overview",
          module: Contexla.TestSurfaceLive,
          role: :instance,
          label: "Test overview"
        }
      ],
      required_adapter_contracts: ["contexla.test.source.v1"]
    }
  end

  @impl true
  def validate_instance_config(config) when is_map(config), do: {:ok, config}
  def validate_instance_config(_config), do: {:error, :invalid_config}

  @impl true
  def available_operations, do: []

  @impl true
  def required_adapter_contracts, do: ["contexla.test.source.v1"]
end

defmodule Contexla.TestSurfaceLive do
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

defmodule Contexla.TestAdapter do
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

defmodule Contexla.TestIntegration do
  alias Contexla.IntegrationSDK.{Adapter, Definition}

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
          module: Contexla.TestAdapter,
          source_types: ["file"]
        }
      ]
    }
  end
end
