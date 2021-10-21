defmodule VelocityWeb.Schema.EmploymentTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo

  @desc "employment"
  object :employment do
    field :id, :id
    field :effective_date, :date
    field :end_date, :date
    field :end_reason, :string
    field :type, :string
    field :status, :string
    field :anticipated_start_date, :date

    field(:partner, :partner) do
      resolve(fn employment, _args, _info ->
        partner = Ecto.assoc(employment, :partner) |> Repo.one()
        {:ok, partner}
      end)
    end

    field(:employee, :employee) do
      resolve(fn employment, _args, _info ->
        employee = Ecto.assoc(employment, :employee) |> Repo.one()
        {:ok, employee}
      end)
    end

    field(:job, :job) do
      resolve(fn employment, _args, _info ->
        job = Ecto.assoc(employment, :job) |> Repo.one()
        {:ok, job}
      end)
    end

    field(:contract, :contract) do
      resolve(fn employment, _args, _info ->
        contract = Ecto.assoc(employment, :contract) |> Repo.one()
        {:ok, contract}
      end)
    end

    field(:country, :country) do
      resolve(fn employment, _args, _info ->
        country = Ecto.assoc(employment, :country) |> Repo.one()
        {:ok, country}
      end)
    end
  end
end
