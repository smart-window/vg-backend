defmodule Velocity.Contexts.AutoTasks do
  alias Velocity.Contexts.Documents
  alias Velocity.Contexts.EmployeeOnboardings
  alias Velocity.Contexts.Tasks
  alias Velocity.Contexts.Training.EmployeeTrainings
  alias Velocity.Notifications
  alias Velocity.Repo
  alias Velocity.Schema.Client
  alias Velocity.Schema.ClientOnboarding
  alias Velocity.Schema.Contract
  alias Velocity.Schema.DependentTask
  alias Velocity.Schema.NotificationTemplate
  alias Velocity.Schema.Task

  import Ecto.Query

  require Logger

  def run_auto_tasks(task) do
    # Runs any "auto" tasks that are dependent upon the given task
    Repo.all(
      from(t in Task,
        join: dt in DependentTask,
        on: dt.dependent_task_id == t.id,
        where: dt.task_id == ^task.id,
        preload: [:task_template]
      )
    )
    |> Enum.each(fn dependent_task ->
      run_auto_task(dependent_task)
    end)
  end

  def run_auto_task(_task = %{completion_type: "auto", status: "completed"}) do
    # an auto task but is complete so skip...
  end

  def run_auto_task(task = %{completion_type: "auto"}) do
    # of the context to determine the task to perform
    task =
      if Ecto.assoc_loaded?(task.task_template) do
        task
      else
        Repo.preload(task, :task_template)
      end

    if !has_dependencies?(task) do
      # the method key within the auto section tells us what auto task to run
      status = run_auto_task_method(task, task.task_template.context["auto"]["method"])
      Tasks.update_status(task, status)
    end
  end

  def run_auto_task(_) do
    # task is not an auto task so do nothing
  end

  defp has_dependencies?(task) do
    # ensure dependent tasks available
    task =
      if Ecto.assoc_loaded?(task.dependent_tasks) do
        task
      else
        Repo.preload(task, :dependent_tasks)
      end

    dependent_task =
      Enum.find(task.dependent_tasks, fn task ->
        task.status != "completed"
      end)

    dependent_task != nil
  end

  defp run_auto_task_method(task, "create_employment_trainings") do
    # ensure any trainings for country of employment is populated
    # into employee_trainings
    # "auto" context supported:
    #   "method": "create_employment_trainings"
    employment = EmployeeOnboardings.get_employment_for_process(task.process_id)

    if employment != nil do
      case EmployeeTrainings.create_for_user_and_country(
             employment.employee.user_id,
             employment.country_id
           ) do
        {:ok, _} ->
          "completed"

        {:error, error} ->
          Logger.error("error creating employment trainings #{error}")
          "failed"

        error ->
          Logger.error("unknown error creating employment trainings #{inspect(error)}")
          "failed"
      end
    else
      Logger.error("no employment found for auto task #{task.id}")
      "failed"
    end
  end

  defp run_auto_task_method(task, "create_employment_documents") do
    # ensure any document templates for the client associated to
    # the employment is added for the employee
    # "auto" context supported:
    #   "method": "create_employment_documents"
    employment = EmployeeOnboardings.get_employment_for_process(task.process_id)

    if employment != nil do
      case Documents.create_for_client_partner_user_and_country(
             employment.contract.client_id,
             employment.partner_id,
             employment.employee.user_id,
             employment.country_id
           ) do
        {:ok, _} ->
          "completed"

        {:error, error} ->
          Logger.error("error creating employment documents #{error}")
          "failed"

        error ->
          Logger.error("unknown error creating employment documents #{inspect(error)}")
          "failed"
      end
    else
      Logger.error("no employment found for auto task #{task.id}")
      "failed"
    end
  end

  defp run_auto_task_method(_task, "create_client_access") do
    Logger.debug("create_client_access called")
    "completed"
  end

  defp run_auto_task_method(task, "send_notification") do
    # sends a notification using the specified notification template
    # "auto" context supported:
    #   "method": "send_notification"
    #   "notification_template": "<name of notification template>"
    #   [ "ignore_if_missing" : true|false ]
    notification_template_name = task.task_template.context["auto"]["notification_template"]

    if notification_template_name != nil do
      # verify notification exists
      notification = Repo.get_by(NotificationTemplate, event: notification_template_name)

      if notification != nil do
        # put as much stuff as we can into the notification context...
        client_onboarding = Repo.get_by(ClientOnboarding, process_id: task.process_id)

        client =
          if client_onboarding != nil do
            contract = Repo.get_by(Contract, id: client_onboarding.contract_id)
            Repo.get(Client, contract.client_id)
          else
            nil
          end

        metadata = %{client: client, task: task}
        Notifications.schedule(String.to_atom(notification_template_name), metadata)
        "completed"
      else
        ignore_if_missing = task.task_template.context["auto"]["ignore_if_missing"] || false

        if ignore_if_missing do
          Logger.warn(
            "no notification named #{notification_template_name} found for auto task #{task.id}"
          )

          "completed"
        else
          Logger.error(
            "no notification named #{notification_template_name} found for auto task #{task.id}"
          )

          "failed"
        end
      end
    else
      Logger.error("no notification template configured for auto task #{task.id}")
      "failed"
    end
  end

  defp run_auto_task_method(task, method) do
    Logger.error(
      "no method implementation found for auto task #{task.id} method #{method}, marking as failed"
    )

    "failed"
  end
end
