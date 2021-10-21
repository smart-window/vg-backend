defmodule Mix.Tasks.Traffic do
  @moduledoc false
  use Mix.Task

  require Logger
  alias VelocityWeb.HttpClients.Http

  def run(_) do
    Application.put_env(:velocity, :minimal, true)
    {:ok, _} = Application.ensure_all_started(:velocity)

    for _x <- 0..100 do
      client = Http.client("https://qa-velocity-api.herokuapp.com")

      times = :rand.uniform(500)

      for _y <- 0..times do
        {:ok, %{body: response}} =
          Tesla.get(
            client,
            "/is_it_up"
          )

        Logger.info(response)
      end

      sleep = :rand.uniform(15_000)
      :timer.sleep(sleep)
    end
  end
end
