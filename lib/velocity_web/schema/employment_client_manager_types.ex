defmodule VelocityWeb.Schema.EmploymentClientManagerTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo

  @desc "employment_client_manager"
  object :employment_client_manager do
    field :id, :id
    field :effective_date, :date

    field(:employment, :employment) do
      resolve(fn employment, _args, _info ->
        employment = Ecto.assoc(employment, :employment) |> Repo.one()
        {:ok, employment}
      end)
    end

    field(:client_manager, :client_manager) do
      resolve(fn client_manager, _args, _info ->
        client_manager = Ecto.assoc(client_manager, :client_manager) |> Repo.one()
        {:ok, client_manager}
      end)
    end
  end
end
