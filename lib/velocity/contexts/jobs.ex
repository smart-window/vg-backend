defmodule Velocity.Contexts.Jobs do
  @moduledoc "context for jobs"

  alias Velocity.Repo
  alias Velocity.Schema.Job

  def get!(id) do
    Repo.get!(Job, id)
  end

  def create(params) do
    %Job{}
    |> Job.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(Job, params.id)
    |> Job.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %Job{id: id}
    |> Repo.delete()
  end
end
