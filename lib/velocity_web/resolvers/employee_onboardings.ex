defmodule VelocityWeb.Resolvers.EmployeeOnboardings do
  @moduledoc """
  GQL resolver for employments
  """

  alias Velocity.Contexts.EmployeeOnboardings

  def get(args, %{context: %{current_user: current_user}}) do
    {:ok, EmployeeOnboardings.get!(current_user.id, String.to_integer(args.id))}
  end

  def employee_onboardings(args, _) do
    employee_onboardings =
      EmployeeOnboardings.get_all(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(employee_onboardings) > 0 do
        Enum.at(employee_onboardings, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, employee_onboardings: employee_onboardings}}
  end

  def create(args, _) do
    EmployeeOnboardings.create(args)
  end

  def start(args, _) do
    EmployeeOnboardings.start(args)
  end

  def update(args, _) do
    EmployeeOnboardings.update(args)
  end

  def delete(args, _) do
    EmployeeOnboardings.delete(String.to_integer(args.id))
  end
end
