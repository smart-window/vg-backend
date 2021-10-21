defmodule Velocity.Contexts.ExternalEmployees do
  @moduledoc "context for external employees"

  alias Velocity.Repo
  alias Velocity.Schema.ExternalEmployee

  def get!(id) do
    Repo.get!(ExternalEmployee, id)
  end

  def create(params) do
    %ExternalEmployee{}
    |> ExternalEmployee.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(ExternalEmployee, params.id)
    |> ExternalEmployee.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %ExternalEmployee{id: id}
    |> Repo.delete()
  end
end
