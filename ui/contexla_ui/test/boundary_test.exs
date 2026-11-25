defmodule Contexla.Ui.ContexlaUi.Test.BoundaryTest do
  use ExUnit.Case, async: true

  test "shared UI remains route and persistence independent" do
    offenders =
      "lib/**/*.ex"
      |> Path.wildcard()
      |> Enum.filter(fn path ->
        source = File.read!(path)

        Enum.any?(
          [
            "ContexlaWeb",
            "Contexla.Platform.Web",
            "Contexla.Repo",
            "Contexla.Platform.Repo",
            "Phoenix.VerifiedRoutes",
            "Ecto.Repo"
          ],
          &String.contains?(source, &1)
        )
      end)

    assert offenders == []
  end
end
