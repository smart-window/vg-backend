defmodule Velocity.Contexts.ProcessesTest do
  use Velocity.DataCase, async: true

  alias Velocity.Contexts.Processes
  alias Velocity.Contexts.Stages
  alias Velocity.Repo
  alias Velocity.Schema.Process
  alias Velocity.Schema.Stage
  alias Velocity.Schema.Task

  import Mox

  describe "Processes.create/2" do
    test "it creates a process with the correct number of tasks" do
      process_template = Factory.insert(:process_template)

      service_ids =
        List.first(process_template.stage_templates)
        |> Map.get(:task_templates)
        |> Enum.map(& &1.service_id)

      Processes.create(process_template.id, service_ids)

      assert Repo.one(Process)
      # each service has 1 tasks
      assert Repo.aggregate(Task, :count) == length(service_ids)
    end
  end

  describe "Processes.filter/2" do
    test "it filters by user assignment" do
      process = Factory.insert(:process)

      task =
        process
        |> Map.get(:stages)
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()

      role = Factory.insert(:role)
      %{user_id: user_id} = Factory.insert(:task_assignment, %{task: task, role: role})

      filtered_process = Processes.filter(process.id, %{user_ids: [user_id]})

      assert filtered_process
             |> Map.get(:stages)
             |> List.first()
             |> Map.get(:tasks)
             |> Enum.count() == 1
    end

    test "it filters by task status" do
      process = Factory.insert(:process)

      task =
        process
        |> Map.get(:stages)
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()

      changeset = Task.changeset(task, %{status: "completed"})
      Repo.update!(changeset)

      filtered_process = Processes.filter(process.id, %{task_statuses: ["completed"]})

      assert filtered_process
             |> Map.get(:stages)
             |> List.first()
             |> Map.get(:tasks)
             |> Enum.count() == 1
    end
  end

  describe "Processes.update_completion_percentage/1" do
    test "it updates the process and stage completion percentage" do
      process = Factory.insert(:process)
      Repo.update_all(Task, set: [process_id: process.id])

      task = Repo.one(from(t in Task, limit: 1))

      changeset = Task.changeset(task, %{status: "completed"})
      updated_task = Repo.update!(changeset)

      assert :ok = Processes.update_completion_percentage(updated_task)

      updated_process = Processes.get_by(id: process.id)
      updated_stage = Stages.get_by(id: task.stage_id)

      assert updated_process.percent_complete == 0.1111111111111111
      assert updated_stage.percent_complete == 0.3333333333333333
    end

    test "it sends a notification when to the 'users_assigned_to_task' when the task is complete" do
      process = Factory.insert(:process)
      Repo.update_all(Process, set: [percent_complete: 100.0])
      Repo.update_all(Stage, set: [process_id: process.id, percent_complete: 100.0])
      Repo.update_all(Task, set: [process_id: process.id, status: "completed"])

      task = Repo.one(from(t in Task, limit: 1))

      role = Factory.insert(:role)
      %{user_id: user_id} = Factory.insert(:task_assignment, %{task: task, role: role})

      notification_template = Factory.insert(:notification_template, %{event: "task_completed"})

      Factory.insert(:notification_default, %{
        notification_template: notification_template,
        actors: ["users_assigned_to_task"]
      })

      MockExq
      |> expect(:enqueue_at, fn _module, _queue, _time, _adapter, args ->
        noti_user = Enum.at(args, 0)
        assert noti_user.id == user_id

        {:ok, :mocked}
      end)

      :ok = Processes.update_completion_percentage(task)
    end
  end

  describe "Knowledge Articles" do
    test "knowledge articles can relate to process templates" do
      process_template =
        Factory.insert(:process_template, %{
          knowledge_articles: [Factory.build(:knowledge_article)]
        })

      assert Enum.count(process_template.knowledge_articles) == 1
    end

    test "knowledge articles can relate to stage templates" do
      stage_template =
        Factory.insert(:stage_template, %{knowledge_articles: [Factory.build(:knowledge_article)]})

      assert Enum.count(stage_template.knowledge_articles) == 1
    end
  end

  describe "Processes.add_services/2" do
    test "it adds tasks for the added service" do
      process_template = Factory.insert(:process_template)

      [service_id_to_add | service_ids] =
        List.first(process_template.stage_templates)
        |> Map.get(:task_templates)
        |> Enum.map(& &1.service_id)

      {:ok, process} = Processes.create(process_template.id, service_ids)

      original_tasks = Enum.count(process.tasks)
      {:ok, updated_process} = Processes.add_services(process.id, [service_id_to_add])

      after_tasks =
        Enum.reduce(updated_process.stages, 0, fn stage, acc ->
          acc + Enum.count(stage.tasks)
        end)

      assert after_tasks > original_tasks
    end
  end

  describe "Processes.remove_services/2" do
    test "it removes tasks for the removed service" do
      process_template = Factory.insert(:process_template)

      service_ids =
        List.first(process_template.stage_templates)
        |> Map.get(:task_templates)
        |> Enum.map(& &1.service_id)

      {:ok, process} = Processes.create(process_template.id, service_ids)

      original_tasks = Enum.count(process.tasks)
      {:ok, updated_process} = Processes.remove_services(process.id, [List.first(service_ids)])

      after_tasks =
        Enum.reduce(updated_process.stages, 0, fn stage, acc ->
          acc + Enum.count(stage.tasks)
        end)

      assert after_tasks < original_tasks
    end
  end
end
