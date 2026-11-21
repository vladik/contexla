defmodule Contexla.ApplicationSDK.PackageBuilderTest do
  use ExUnit.Case, async: true

  alias Contexla.ApplicationSDK.{Definition, Surface}
  alias Contexla.ApplicationSDK.PackageBuilder

  defmodule PackagedApplication do
    @behaviour Contexla.ApplicationSDK.Application

    @impl true
    def definition do
      %Definition{
        id: "com.example.application",
        name: "Example Application",
        icon: "hero-beaker",
        version: "1.0.0",
        otp_application: :example,
        entry_module: __MODULE__,
        operations: [],
        surfaces: [
          %Surface{id: :new, path: "new", module: __MODULE__, role: :new},
          %Surface{id: :home, path: "home", module: __MODULE__, role: :instance, default: true},
          %Surface{
            id: :settings,
            path: "settings",
            module: __MODULE__,
            role: :instance,
            kind: :settings
          }
        ],
        required_adapter_contracts: []
      }
    end

    @impl true
    def validate_instance_config(config), do: {:ok, config}

    @impl true
    def available_operations, do: []

    @impl true
    def required_adapter_contracts, do: []
  end

  test "builds a deterministic archive with compiled code, priv files, and checksums" do
    root = Path.join(System.tmp_dir!(), "contexla-package-#{System.unique_integer([:positive])}")
    app_path = Path.join(root, "app")
    File.mkdir_p!(Path.join(app_path, "ebin"))
    File.mkdir_p!(Path.join(app_path, "priv/repo/migrations"))
    File.write!(Path.join(app_path, "ebin/example.app"), "compiled")
    File.write!(Path.join(app_path, "priv/repo/migrations/001.exs"), "migration")

    manifest_path = Path.join(root, "contexla-application.json")

    File.write!(
      manifest_path,
      Jason.encode!(%{
        "manifestVersion" => 1,
        "applicationId" => "com.example.application",
        "name" => "Example Application",
        "icon" => "hero-beaker",
        "version" => "1.0.0",
        "otpApplication" => "example",
        "entryModule" => "Contexla.ApplicationSDK.PackageBuilderTest.PackagedApplication",
        "sdkRequirement" => "~> 0.1",
        "operations" => [],
        "surfaces" => [
          %{
            "id" => "new",
            "path" => "new",
            "module" => "Contexla.ApplicationSDK.PackageBuilderTest.PackagedApplication",
            "role" => "new"
          },
          %{
            "id" => "home",
            "path" => "home",
            "module" => "Contexla.ApplicationSDK.PackageBuilderTest.PackagedApplication",
            "role" => "instance",
            "default" => true
          },
          %{
            "id" => "settings",
            "path" => "settings",
            "module" => "Contexla.ApplicationSDK.PackageBuilderTest.PackagedApplication",
            "role" => "instance",
            "kind" => "settings"
          }
        ]
      })
    )

    first = Path.join(root, "first.contexla-app")
    second = Path.join(root, "second.contexla-app")
    on_exit(fn -> File.rm_rf(root) end)

    assert {:ok, first_result} = PackageBuilder.build(manifest_path, app_path, first)
    assert {:ok, second_result} = PackageBuilder.build(manifest_path, app_path, second)
    assert first_result.digest == second_result.digest
    assert File.read!(first) == File.read!(second)

    assert {:ok, entries} = :zip.extract(String.to_charlist(first), [:memory])
    names = Enum.map(entries, fn {name, _bytes} -> to_string(name) end)
    assert "contexla-application.json" in names
    assert "lib/example-1.0.0/ebin/example.app" in names
    assert "lib/example-1.0.0/priv/repo/migrations/001.exs" in names
    assert "CHECKSUMS" in names
  end

  test "rejects a manifest that disagrees with compiled Application identity" do
    root = Path.join(System.tmp_dir!(), "contexla-package-#{System.unique_integer([:positive])}")
    app_path = Path.join(root, "app")
    File.mkdir_p!(Path.join(app_path, "ebin"))
    File.write!(Path.join(app_path, "ebin/example.app"), "compiled")
    manifest_path = Path.join(root, "contexla-application.json")
    on_exit(fn -> File.rm_rf(root) end)

    File.write!(
      manifest_path,
      Jason.encode!(%{
        "manifestVersion" => 1,
        "applicationId" => "com.example.wrong",
        "name" => "Example Application",
        "icon" => "hero-beaker",
        "version" => "1.0.0",
        "otpApplication" => "example",
        "entryModule" => "Contexla.ApplicationSDK.PackageBuilderTest.PackagedApplication",
        "sdkRequirement" => "~> 0.1",
        "operations" => [],
        "surfaces" => [
          %{
            "id" => "new",
            "path" => "new",
            "module" => "Contexla.ApplicationSDK.PackageBuilderTest.PackagedApplication",
            "role" => "new"
          },
          %{
            "id" => "home",
            "path" => "home",
            "module" => "Contexla.ApplicationSDK.PackageBuilderTest.PackagedApplication",
            "role" => "instance",
            "default" => true
          },
          %{
            "id" => "settings",
            "path" => "settings",
            "module" => "Contexla.ApplicationSDK.PackageBuilderTest.PackagedApplication",
            "role" => "instance",
            "kind" => "settings"
          }
        ]
      })
    )

    assert {:error,
            {:manifest_definition_mismatch, :application_id, "com.example.wrong",
             "com.example.application"}} =
             PackageBuilder.build(
               manifest_path,
               app_path,
               Path.join(root, "invalid.contexla-app")
             )
  end
end
