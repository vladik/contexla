defmodule Contexla.Applications.Sdk.Test.ErrorTest do
  use ExUnit.Case, async: true

  alias Contexla.Applications.Sdk.Error

  test "returns stable atom and tagged-tuple codes" do
    assert Error.code(:timeout) == "timeout"
    assert Error.code({:invalid_input, %{secret: "must not escape"}}) == "invalid_input"
  end

  test "does not expose arbitrary terms" do
    refute Error.code("password=secret") =~ "secret"
    assert Error.code(%RuntimeError{message: "token=secret"}, "safe_failure") == "safe_failure"
    assert Error.map({"unsafe", "secret"}, "safe_failure") == %{"code" => "safe_failure"}
  end
end
