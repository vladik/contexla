defmodule ContexlaUIBoundaryTest do
  use ExUnit.Case, async: true

  test "shared UI remains route and persistence independent" do
    offenders =
      "lib/**/*.ex"
      |> Path.wildcard()
      |> Enum.filter(fn path ->
        source = File.read!(path)

        Enum.any?(
          ["ContexlaWeb", "Contexla.Repo", "Phoenix.VerifiedRoutes", "Ecto.Repo"],
          &String.contains?(source, &1)
        )
      end)

    assert offenders == []
  end
end
