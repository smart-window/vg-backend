defmodule VelocityWeb.Resolvers.Tasks do
  @moduledoc """
  GQL resolver for tasks
  """

  alias Velocity.Contexts.Tasks

  def assign(%{user_id: user_id, task_id: task_id, role_id: role_id}, _) do
    Tasks.assign(user_id, task_id, role_id)
  end

  def add_comment(
        %{task_id: task_id, comment: comment, visibility_type: visibility_type},
        %{context: %{current_user: current_user}}
      ) do
    Tasks.add_comment(
      current_user.id,
      task_id,
      comment,
      String.to_atom(Macro.underscore(visibility_type))
    )
  end

  def delete_comment(%{id: id}, _) do
    Tasks.delete_comment(String.to_integer(id))
  end

  def get(%{id: id}, _) do
    {:ok, Tasks.get_by(id: id)}
  end

  def update_status(%{task_id: task_id, status: status}, _) do
    Tasks.update_status(task_id, status)
  end
end
