defmodule Contexla.TestApplication do
  @behaviour Contexla.ApplicationSDK.Application

  alias Contexla.ApplicationSDK.{Definition, Surface}

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
      operations: [],
      surfaces: [
        %Surface{
          id: :new,
          path: "new",
          module: Contexla.TestNewSurfaceLive,
          role: :new,
          label: "New test"
        },
        %Surface{
          id: :overview,
          path: "overview",
          module: Contexla.TestSurfaceLive,
          role: :instance,
          default: true,
          label: "Test overview"
        },
        %Surface{
          id: :settings,
          path: "configuration",
          module: Contexla.TestSettingsSurfaceLive,
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
  def available_operations, do: []

  @impl true
  def required_adapter_contracts, do: ["contexla.test.source.v1"]
end

defmodule Contexla.TestSettingsSurfaceLive do
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

defmodule Contexla.TestNewSurfaceLive do
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
