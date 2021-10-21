defmodule Velocity.Contexts.TasksTest do
  use Velocity.DataCase, async: true

  alias Velocity.Contexts.Tasks
  alias Velocity.Repo
  alias Velocity.Schema.TaskAssignment

  describe "Tasks.assign/2" do
    test "it assigns the user to the task" do
      process = Factory.insert(:process)
      user = Factory.insert(:user)
      role = Factory.insert(:role)

      task_id =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()
        |> Map.get(:id)

      assert {:ok, _} = Tasks.assign(user.id, task_id, role.id)
      assert Repo.one(TaskAssignment)
    end
  end

  describe "Tasks.update_status/2" do
    test "it changes the status from not_started to in_progress" do
      process = Factory.insert(:process)

      task_id =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()
        |> Map.get(:id)

      assert {:ok, %{status: "in_progress"}} = Tasks.update_status(task_id, "in_progress")
    end
  end
end
