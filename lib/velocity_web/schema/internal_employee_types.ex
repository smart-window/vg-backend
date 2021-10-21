defmodule VelocityWeb.Schema.InternalEmployeeTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo
  alias Velocity.Schema.User

  @desc "internal_employee"
  object :internal_employee do
    field :id, :id
    field :job_title, :string

    field(:employee, :employee) do
      resolve(fn employee, _args, _info ->
        employee = Ecto.assoc(employee, :employee) |> Repo.one()
        {:ok, employee}
      end)
    end
  end

  object :internal_employees_report_item do
    field :id, :id
    field :name, :string
    field :email, :string
    field :job_title, :string

    field(:roles, list_of(:role)) do
      resolve(fn item, _args, _info ->
        user = User |> Repo.get(item.user_id) |> Repo.preload(:roles)
        {:ok, user.roles}
      end)
    end
  end

  object :paginated_internal_employees_report do
    field :row_count, :integer
    field :internal_employees_report_items, list_of(:internal_employees_report_item)
  end
end
