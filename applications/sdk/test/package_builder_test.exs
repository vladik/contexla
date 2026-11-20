defmodule Contexla.ApplicationSDK.PackageBuilderTest do
  use ExUnit.Case, async: true

  alias Contexla.ApplicationSDK.PackageBuilder

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
        "icon" => "hero-beaker",
        "version" => "1.0.0",
        "otpApplication" => "example",
        "entryModule" => "Example.Application",
        "surfaces" => [
          %{"id" => "new", "path" => "new", "module" => "Example.NewLive", "role" => "new"},
          %{
            "id" => "home",
            "path" => "home",
            "module" => "Example.HomeLive",
            "role" => "instance",
            "default" => true
          },
          %{
            "id" => "settings",
            "path" => "settings",
            "module" => "Example.SettingsLive",
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
end
