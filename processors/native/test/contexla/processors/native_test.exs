defmodule Contexla.Processors.NativeTest do
  use ExUnit.Case

  alias Contexla.Processors.Native.ParseComposerDependencies

  test "registers a native Processor for Parse Composer Dependencies" do
    assert {:ok, [processor]} =
             Contexla.CapabilitySDK.validate_processor_package(Contexla.Processors.Native)

    assert processor.capability_id == "com.contexla.dependencies.parse-composer"
    assert processor.version == "0.2.0"
    assert processor.capability_contract_version == "2"
    assert processor.runtime == :native
    assert processor.default
  end

  test "normalizes production and development Composer dependencies" do
    input = %{
      "composer_json" => %{
        "require" => %{"drupal/core" => "^10"},
        "require-dev" => %{"phpunit/phpunit" => "^10"}
      },
      "composer_lock" => %{
        "packages" => [
          %{"name" => "drupal/core", "version" => "10.3.0", "type" => "drupal-core"}
        ],
        "packages-dev" => [
          %{"name" => "phpunit/phpunit", "version" => "10.5.0", "type" => "library"}
        ]
      }
    }

    assert {:ok, %{"dependencies" => [drupal, phpunit]}} =
             ParseComposerDependencies.execute(input, %{})

    assert drupal == %{
             "name" => "drupal/core",
             "version" => "10.3.0",
             "type" => "drupal-core",
             "development" => false,
             "direct" => true
           }

    assert phpunit["development"]
    assert phpunit["direct"]
  end
end
