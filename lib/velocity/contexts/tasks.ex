defmodule Velocity.Contexts.Tasks do
  alias Velocity.Contexts.AutoTasks
  alias Velocity.Contexts.Processes
  alias Velocity.Repo
  alias Velocity.Schema.Task
  alias Velocity.Schema.TaskAssignment
  alias Velocity.Schema.TaskComment

  require Logger

  def assign(user_id, task_id, role_id) do
    changeset =
      TaskAssignment.changeset(%TaskAssignment{}, %{
        user_id: user_id,
        task_id: task_id,
        role_id: role_id
      })

    case Repo.insert(changeset) do
      {:ok, task_assignment} ->
        {:ok, get_by(id: task_assignment.task_id)}

      error ->
        error
    end
  end

  def get_by(keyword) do
    task =
      Task
      |> Repo.get_by(keyword)
      |> Repo.preload(task_assignments: :user)
      |> Repo.preload(task_comments: :user)
      |> Repo.preload(:task_template)

    Map.put(task, :name, task.task_template.name)
  end

  def update_status(task = %Task{}, args) do
    handle_update(task, args)
  end

  def update_status(task_id, args) do
    task = get_by(id: task_id)

    handle_update(task, args)
  end

  defp handle_update(task, status) do
    changeset = Task.changeset(task, %{status: status})

    case Repo.update(changeset) do
      {:ok, task} ->
        handle_completion(task)

        {:ok, get_by(id: task.id)}

      error ->
        error
    end
  end

  defp handle_completion(task = %Task{status: "completed"}) do
    :ok = Processes.update_completion_percentage(task)
    :ok = Processes.task_status_changed(task)
    :ok = AutoTasks.run_auto_tasks(task)
  end

  defp handle_completion(task = %Task{status: "not_started"}) do
    :ok = Processes.update_completion_percentage(task)
    :ok = Processes.task_status_changed(task)
  end

  defp handle_completion(_), do: :noop

  def add_comment(user_id, task_id, comment, visibility_type \\ :internal_only) do
    changeset =
      TaskComment.changeset(
        %TaskComment{},
        %{
          user_id: user_id,
          task_id: task_id,
          comment: comment,
          visibility_type: visibility_type
        }
      )

    case Repo.insert(changeset) do
      {:ok, task_comment} ->
        {:ok, get_by(id: task_comment.task_id)}

      error ->
        error
    end
  end

  def delete_comment(id) do
    %TaskComment{id: id}
    |> Repo.delete()
  end
end
