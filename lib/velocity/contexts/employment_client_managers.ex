defmodule Velocity.Contexts.EmploymentClientManagers do
  @moduledoc "context for employment to client manager associations"

  alias Velocity.Repo
  alias Velocity.Schema.EmploymentClientManager

  def get!(id) do
    Repo.get!(EmploymentClientManager, id)
  end

  def create(params) do
    %EmploymentClientManager{}
    |> EmploymentClientManager.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(EmploymentClientManager, params.id)
    |> EmploymentClientManager.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %EmploymentClientManager{id: id}
    |> Repo.delete()
  end
end
