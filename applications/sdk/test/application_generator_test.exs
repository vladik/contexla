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
      "--id",
      "com.acme.application.starter",
      "--name",
      "Starter"
    ])

    assert File.exists?(Path.join(target, "mix.exs"))
    assert File.exists?(Path.join(target, "contexla-application.json"))
    assert File.exists?(Path.join(target, "lib/web/overview_live.ex"))

    generated_module = "Contexla.Applications." <> (target |> Path.basename() |> Macro.camelize())

    mix_file = File.read!(Path.join(target, "mix.exs"))
    refute mix_file =~ ~r/[A-Za-z]:\//

    definition = File.read!(Path.join(target, "lib/package.ex"))
    refute definition =~ "ContexlaWeb"
    assert definition =~ "Contexla.Applications.Sdk"
    assert definition =~ generated_module <> ".Package"

    new_surface = File.read!(Path.join(target, "lib/web/new_live.ex"))
    assert new_surface =~ "Runtime.create_instance"
    refute new_surface =~ "Runtime.call"

    manifest = target |> Path.join("contexla-application.json") |> File.read!() |> Jason.decode!()
    assert manifest["applicationId"] == "com.acme.application.starter"
    assert manifest["entryModule"] == generated_module <> ".Package"
    assert Enum.any?(manifest["surfaces"], &(&1["default"] == true))
    assert Enum.any?(manifest["surfaces"], &(&1["kind"] == "settings"))
  end
end
