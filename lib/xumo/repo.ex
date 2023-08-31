defmodule Xumo.Repo do
  use Ecto.Repo,
    otp_app: :xumo,
    adapter: Ecto.Adapters.Postgres
end
