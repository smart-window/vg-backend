defmodule Velocity.Contexts.Pto.PtoRequests do
  @moduledoc "context for pto_requests"

  alias Velocity.Repo
  alias Velocity.Schema.Pto.PtoRequest

  def get!(id) do
    Repo.get!(PtoRequest, id)
  end

  def create(params) do
    %PtoRequest{}
    |> PtoRequest.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(PtoRequest, params.id)
    |> PtoRequest.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %PtoRequest{id: id}
    |> Repo.delete()
  end
end
