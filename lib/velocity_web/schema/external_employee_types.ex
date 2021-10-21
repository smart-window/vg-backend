defmodule VelocityWeb.Schema.ExternalEmployeeTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo

  @desc "external_employee"
  object :external_employee do
    field :id, :id

    field(:employee, :employee) do
      resolve(fn employee, _args, _info ->
        employee = Ecto.assoc(employee, :employee) |> Repo.one()
        {:ok, employee}
      end)
    end
  end
end
