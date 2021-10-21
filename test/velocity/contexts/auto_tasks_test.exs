defmodule Velocity.Contexts.AutoTasksTest do
  use Velocity.DataCase, async: true

  alias Velocity.Contexts.Processes
  alias Velocity.Contexts.Tasks
  alias Velocity.EmploymentHelpers
  alias Velocity.Schema.Task
  alias Velocity.Schema.Training.EmployeeTraining
  alias Velocity.Schema.UserDocument

  def setup_process(auto_task_context) do
    service = Factory.insert(:service)
    process_template = Factory.insert(:custom_process_template, %{type: "My Process Template"})

    stage_template =
      Factory.insert(:custom_stage_template, %{
        order: 1,
        name: "Stage One",
        process_template: process_template
      })

    to_be_completed_task_template =
      Factory.insert(:custom_task_template, %{
        service: service,
        order: 1,
        completion_type: "check_off",
        stage_template: stage_template
      })

    auto_task_template =
      Factory.insert(:custom_task_template, %{
        service: service,
        order: 2,
        completion_type: "auto",
        stage_template: stage_template,
        context: auto_task_context
      })

    Factory.insert(:dependent_task_template, %{
      task_template: to_be_completed_task_template,
      dependent_task_template: auto_task_template
    })

    {:ok, process} = Processes.create(process_template.id, [service.id])
    process
  end

  describe "it runs auto tasks" do
    test "it runs the trainings task" do
      process =
        setup_process(%{
          auto: %{
            method: "create_employment_trainings"
          }
        })

      user = Factory.insert(:user)
      employment = EmploymentHelpers.setup_employment(user)
      training = Factory.insert(:training)

      Factory.insert(:training_country, %{
        training: training,
        country: employment.country
      })

      Factory.insert(:employee_onboarding, %{
        employment: employment,
        process: process
      })

      to_be_completed_task =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()

      trainings_task =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.last()

      Tasks.update_status(to_be_completed_task, "completed")
      to_be_completed_task = Repo.get(Task, to_be_completed_task.id)
      assert to_be_completed_task.status == "completed"
      trainings_task = Repo.get(Task, trainings_task.id)
      assert trainings_task.status == "completed"

      assert Repo.one(
               from et in EmployeeTraining,
                 where: et.user_id == ^user.id and et.training_id == ^training.id
             )
    end

    test "it runs the documents task" do
      process =
        setup_process(%{
          auto: %{
            method: "create_employment_documents"
          }
        })

      user = Factory.insert(:user)
      employment = EmploymentHelpers.setup_employment(user)

      Factory.insert(:employee_onboarding, %{
        employment: employment,
        process: process
      })

      Factory.insert(:document_template, %{
        client: employment.contract.client
      })

      to_be_completed_task =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()

      documents_task =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.last()

      Tasks.update_status(to_be_completed_task, "completed")
      to_be_completed_task = Repo.get(Task, to_be_completed_task.id)
      assert to_be_completed_task.status == "completed"
      documents_task = Repo.get(Task, documents_task.id)
      assert documents_task.status == "completed"

      assert Repo.one(
               from d in UserDocument,
                 where: d.user_id == ^user.id
             )
    end

    test "it runs the send notification task" do
      process =
        setup_process(%{
          auto: %{
            method: "send_notification",
            notification_template: "fubar"
          }
        })

      user = Factory.insert(:user)
      employment = EmploymentHelpers.setup_employment(user)

      Factory.insert(:employee_onboarding, %{
        employment: employment,
        process: process
      })

      notification_template =
        Factory.insert(:notification_template, %{
          event: "fubar"
        })

      Factory.insert(:custom_notification_default, %{
        notification_template: notification_template,
        channel: "email",
        minutes_from_event: 0
      })

      to_be_completed_task =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()

      send_notification_task =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.last()

      Tasks.update_status(to_be_completed_task, "completed")
      to_be_completed_task = Repo.get(Task, to_be_completed_task.id)
      assert to_be_completed_task.status == "completed"
      send_notification_task = Repo.get(Task, send_notification_task.id)
      assert send_notification_task.status == "completed"
    end
  end
end
