defmodule VelocityWeb.Resolvers.InternalEmployees do
  @moduledoc """
  GQL resolver for internal employees
  """

  alias Velocity.Contexts.Employees
  alias Velocity.Contexts.Groups
  alias Velocity.Contexts.InternalEmployees
  alias Velocity.Contexts.Users

  def get(args, _) do
    {:ok, InternalEmployees.get!(String.to_integer(args.id))}
  end

  def create(args, _) do
    # okta_user_uid is a random string until we have a clear workflow of how to create a new user login
    okta_user_uid = for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>

    {:ok, user} =
      Users.create(%{
        first_name: args.first_name,
        last_name: args[:last_name],
        email: args.email,
        timezone: args[:timezone],
        okta_user_uid: okta_user_uid
      })

    csr_group = Groups.get_by(slug: "csr")
    Users.assign_user_to_group(user, csr_group, false)

    role_ids =
      Enum.map(String.split(args.role_ids, ","), fn role_id -> String.to_integer(role_id) end)

    Users.assign_roles_to_user_by_id(user, role_ids)

    {:ok, employee} =
      Employees.create(%{
        user_id: user.id
      })

    InternalEmployees.create(%{
      employee_id: employee.id,
      job_title: args[:job_title]
    })
  end

  def update(args, _) do
    InternalEmployees.update(args)
  end

  def delete(args, _) do
    InternalEmployees.delete(String.to_integer(args.id))
  end

  def assign_role(args, _) do
    internal_employee = InternalEmployees.preload(args.id)

    if args.assign do
      Users.assign_roles_to_user_by_id(internal_employee.employee.user, [
        String.to_integer(args.role_id)
      ])
    else
      Users.remove_user_roles_by_id(internal_employee.employee.user, [
        String.to_integer(args.role_id)
      ])
    end

    {:ok, true}
  end

  def paginated_internal_employees_report(args, _) do
    internal_employees_report_items =
      InternalEmployees.paginated_internal_employees_report(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(internal_employees_report_items) > 0 do
        Enum.at(internal_employees_report_items, 0)[:sql_row_count]
      else
        0
      end

    {:ok,
     %{row_count: row_count, internal_employees_report_items: internal_employees_report_items}}
  end
end
