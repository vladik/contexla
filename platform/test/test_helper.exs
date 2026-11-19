ExUnit.start()

if Process.whereis(Contexla.Repo) do
  Ecto.Adapters.SQL.Sandbox.mode(Contexla.Repo, :manual)
end
