defmodule Velocity.Contexts.InternalEmployees do
  @moduledoc "context for employees"

  alias Ecto.Query

  alias Velocity.Repo
  alias Velocity.Schema.Employee
  alias Velocity.Schema.InternalEmployee
  alias Velocity.Schema.User
  alias Velocity.Schema.UserRole

  import Ecto.Query

  def get!(id) do
    Repo.get!(InternalEmployee, id)
  end

  def preload(id) do
    InternalEmployee |> Repo.get(id) |> Repo.preload(employee: :user)
  end

  def create(params) do
    %InternalEmployee{}
    |> InternalEmployee.changeset(params)
    |> Repo.insert()
  end

  def update(params) do
    internal_employee = InternalEmployee |> Repo.get(params.id) |> Repo.preload(employee: :user)

    internal_employee.employee.user
    |> User.changeset(params)
    |> Repo.update()

    Repo.get!(InternalEmployee, params.id)
    |> InternalEmployee.changeset(params)
    |> Repo.update()
  end

  def delete(id) do
    %InternalEmployee{id: id}
    |> Repo.delete()
  end

  def paginated_internal_employees_report(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    query =
      internal_employees_report_query(
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      )

    query = Query.limit(query, ^page_size)
    Repo.all(query)
  end

  def internal_employees_report_query(
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    last_record_clause =
      build_last_record_clause(last_id, last_value, sort_column, sort_direction)

    order_by_clause = build_order_by_clause(sort_column, sort_direction)
    filter_clause = build_filter_clause(filter_by)
    search_clause = build_search_clause(search_by)

    from(internal_employee in InternalEmployee,
      as: :internal_employee,
      left_join: employee in Employee,
      as: :employee,
      on: employee.id == internal_employee.employee_id,
      left_join: user in User,
      as: :user,
      on: user.id == employee.user_id,
      left_join: user_role in UserRole,
      as: :user_role,
      on: user_role.user_id == user.id,
      where: ^last_record_clause,
      where: ^filter_clause,
      where: ^search_clause,
      order_by: ^order_by_clause,
      distinct: internal_employee.id,
      select: %{
        id: internal_employee.id,
        user_id: user.id,
        name: user.full_name,
        email: user.email,
        job_title: internal_employee.job_title,
        sql_row_count: fragment("count(*) over()")
      }
    )
  end

  defp build_last_record_clause(0, _last_value, _sort_column, _sort_direction) do
    dynamic(true)
  end

  defp build_last_record_clause(last_id, last_value, sort_column, sort_direction) do
    cond do
      Enum.member?([:name], sort_column) ->
        last_record_clause(
          sort_direction,
          :internal_employee,
          :user,
          :full_name,
          last_id,
          last_value
        )

      Enum.member?([:email], sort_column) ->
        last_record_clause(sort_direction, :internal_employee, :user, :email, last_id, last_value)
    end
  end

  defp last_record_clause(sort_direction, primary, table, sort_column, last_id, last_value) do
    if sort_direction == :asc do
      dynamic(
        [{^primary, p}, {^table, x}],
        field(x, ^sort_column) > ^last_value or
          (field(x, ^sort_column) == ^last_value and p.id > ^last_id)
      )
    else
      dynamic(
        [{^primary, p}, {^table, x}],
        field(x, ^sort_column) < ^last_value or
          (field(x, ^sort_column) == ^last_value and p.id > ^last_id)
      )
    end
  end

  defp build_order_by_clause(:name, sort_direction) do
    [{sort_direction, dynamic([user: u], u.full_name)}, asc: :id]
  end

  defp build_order_by_clause(:email, sort_direction) do
    [{sort_direction, dynamic([user: u], u.email)}, asc: :id]
  end

  defp build_filter_clause(filter_by) do
    Enum.reduce(filter_by, dynamic(true), fn filter, filter_clause ->
      where_clause = build_filter_where_clause(Macro.underscore(filter.name), filter.value)
      dynamic([], ^filter_clause and ^where_clause)
    end)
  end

  defp build_filter_where_clause("role_id", value) do
    role_ids = String.split(value, ",")
    dynamic([user_role: ur], ur.role_id in ^role_ids)
  end

  defp build_search_clause(search_by) do
    if search_by != nil && String.trim(search_by) != "" do
      search_by_value = "#{String.trim(search_by)}:*"

      dynamic(
        [user: u],
        fragment("to_tsvector(?) @@ plainto_tsquery(?)", u.full_name, ^search_by_value)
      )
    else
      dynamic(true)
    end
  end
end
