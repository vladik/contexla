ExUnit.start()

if Process.whereis(Contexla.Platform.Repo) do
  Ecto.Adapters.SQL.Sandbox.mode(Contexla.Platform.Repo, :manual)
end
