defmodule Cyanea.Repo do
  use Ecto.Repo,
    otp_app: :cyanea,
    adapter: Ecto.Adapters.SQLite3
end
