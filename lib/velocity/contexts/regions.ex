defmodule Velocity.Contexts.Regions do
  @moduledoc "context for regions"

  alias Velocity.Repo
  alias Velocity.Schema.Region

  def get!(id) do
    Repo.get!(Region, id)
  end

  def create(params) do
    %Region{}
    |> Region.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(Region, params.id)
    |> Region.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %Region{id: id}
    |> Repo.delete()
  end

  def all do
    Repo.all(Region)
  end
end
