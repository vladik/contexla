defmodule Mix.Tasks.Contexla.Application.NewTest do
  use ExUnit.Case, async: false

  test "generates an independent Application project with required surfaces" do
    target =
      Path.join([
        File.cwd!(),
        "tmp",
        "starter_#{System.unique_integer([:positive])}"
      ])

    on_exit(fn -> File.rm_rf!(target) end)
    Mix.Task.reenable("contexla.application.new")

    Mix.Tasks.Contexla.Application.New.run([
      target,
      "--module",
      "Acme.Starter",
      "--id",
      "com.acme.application.starter",
      "--name",
      "Starter"
    ])

    assert File.exists?(Path.join(target, "mix.exs"))
    assert File.exists?(Path.join(target, "contexla-application.json"))
    assert File.exists?(Path.join(target, "lib/overview_live.ex"))

    definition = File.read!(Path.join(target, "lib/application.ex"))
    refute definition =~ "ContexlaWeb"
    assert definition =~ "Contexla.ApplicationSDK"

    manifest = target |> Path.join("contexla-application.json") |> File.read!() |> Jason.decode!()
    assert manifest["applicationId"] == "com.acme.application.starter"
    assert Enum.any?(manifest["surfaces"], &(&1["default"] == true))
    assert Enum.any?(manifest["surfaces"], &(&1["kind"] == "settings"))
  end
end
