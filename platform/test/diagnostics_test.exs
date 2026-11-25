defmodule Contexla.Platform.Test.DiagnosticsTest do
  use Contexla.Platform.Test.Support.DataCase, async: false

  alias Contexla.Platform.Diagnostics

  test "reports a bounded error when artifact storage is unavailable" do
    previous = Application.fetch_env!(:contexla, :artifact_storage_path)

    missing =
      Path.join(System.tmp_dir!(), "contexla-missing-#{System.unique_integer([:positive])}")

    File.rm_rf!(missing)
    Application.put_env(:contexla, :artifact_storage_path, missing)

    on_exit(fn -> Application.put_env(:contexla, :artifact_storage_path, previous) end)

    result = Diagnostics.check()
    assert result.status == :error
    assert result.checks.artifact_storage == :error
    assert result.checks.database == :ok
  end
end
