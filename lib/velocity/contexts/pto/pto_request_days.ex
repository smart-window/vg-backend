defmodule Velocity.Contexts.Pto.PtoRequestDays do
  @moduledoc "context for pto_request_days"

  alias Velocity.Repo
  alias Velocity.Schema.Pto.PtoRequestDay

  def get!(id) do
    Repo.get!(PtoRequestDay, id)
  end

  def create(params) do
    %PtoRequestDay{}
    |> PtoRequestDay.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    Repo.get!(PtoRequestDay, params.id)
    |> PtoRequestDay.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %PtoRequestDay{id: id}
    |> Repo.delete()
  end
end
