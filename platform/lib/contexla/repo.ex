defmodule Contexla.Repo do
  use Ecto.Repo,
    otp_app: :contexla,
    adapter: Ecto.Adapters.Postgres
end
