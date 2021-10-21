defmodule Velocity.Contexts.Stages do
  alias Velocity.Repo
  alias Velocity.Schema.Stage

  def get_by(keyword) do
    Stage
    |> Repo.get_by(keyword)
    |> Repo.preload(:tasks)
  end
end
