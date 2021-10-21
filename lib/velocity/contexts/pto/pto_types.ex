defmodule Velocity.Contexts.Pto.PtoTypes do
  @moduledoc "context for pto_types"

  alias Velocity.Repo
  alias Velocity.Schema.Pto.PtoType

  def get!(id) do
    Repo.get!(PtoType, id)
  end

  def create(params) do
    %PtoType{}
    |> PtoType.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(PtoType, params.id)
    |> PtoType.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %PtoType{id: id}
    |> Repo.delete()
  end
end
