defmodule VelocityWeb.Resolvers.Training.EmployeeTrainings do
  @moduledoc """
    resolver for employee trainings
  """

  alias Velocity.Contexts.Training.EmployeeTrainings

  def for_current_user(_args, %{context: %{current_user: current_user}}) do
    {:ok, EmployeeTrainings.for_user(current_user.id)}
  end

  def for_user(args, _) do
    user_id =
      if Map.get(args, :user_id) do
        args.user_id
      end

    {:ok, EmployeeTrainings.for_user(user_id)}
  end

  def get(args, _) do
    employee_training = EmployeeTrainings.get_by(id: args.employee_training_id)
    {:ok, employee_training}
  end

  def create_employee_training(args, %{context: %{current_user: current_user}}) do
    employee_training_params = %{
      training_id: args.training_id,
      user_id: current_user.id,
      status: args.status,
      due_date: args.due_date
    }

    case EmployeeTrainings.create(employee_training_params) do
      {:ok, created_employee_training} ->
        {:ok, created_employee_training}

      {:error, error} ->
        {:error, error}
    end
  end

  def update_employee_training(args, %{context: %{current_user: current_user}}) do
    params = %{
      id: args.id,
      training_id: args.training_id,
      user_id: current_user.id,
      due_date: args.due_date,
      status: args.status,
      completed_date:
        if Map.has_key?(args, :completed_date) do
          args.completed_date
        else
          nil
        end
    }

    case EmployeeTrainings.update(params) do
      {:ok, created_employee_training} ->
        {:ok, created_employee_training}

      {:error, error} ->
        {:error, error}
    end
  end

  def delete_employee_training(args, _) do
    case EmployeeTrainings.delete(args.id) do
      {:error, error} ->
        {:error, error}
    end
  end

  def employee_trainings_report(args, _) do
    employee_training_report_items =
      EmployeeTrainings.employee_trainings_report(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(employee_training_report_items) > 0 do
        Enum.at(employee_training_report_items, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, employee_training_report_items: employee_training_report_items}}
  end
end
