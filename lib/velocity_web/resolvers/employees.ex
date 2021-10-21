defmodule VelocityWeb.Resolvers.Employees do
  @moduledoc """
  GQL resolver for employees
  """

  alias Velocity.Contexts.Employees

  def get(args, _) do
    if is_nil(Map.get(args, :id)) do
      {:ok, Employees.get_by!(user_id: String.to_integer(args.user_id))}
    else
      {:ok, Employees.get!(String.to_integer(args.id))}
    end
  end

  def create(args, _) do
    Employees.create(args)
  end

  def update(args, _) do
    Employees.update(args)
  end

  def delete(args, _) do
    Employees.delete(String.to_integer(args.id))
  end

  def paginated_employees_report(args, _) do
    employee_report_items =
      Employees.paginated_employees_report(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(employee_report_items) > 0 do
        Enum.at(employee_report_items, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, employee_report_items: employee_report_items}}
  end
end
