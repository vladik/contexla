alias Contexla.Applications.ContentIntegrityMonitor.Test.Simulators.ExternalHttpSource

port = System.get_env("INTEGRITY_DEMO_PORT", "4205") |> String.to_integer()
{:ok, _supervisor} = ExternalHttpSource.start_link(port: port)
Process.sleep(:infinity)
