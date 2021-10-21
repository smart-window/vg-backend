defmodule Velocity.Schema.TaskComment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Task
  alias Velocity.Schema.User

  schema "task_comments" do
    belongs_to :task, Task
    belongs_to :user, User

    field :comment, :string
    field :visibility_type, TaskCommentVisibilityType

    timestamps()
  end

  @doc false
  def changeset(task_comment, attrs) do
    task_comment
    |> cast(attrs, [:task_id, :user_id, :comment, :visibility_type])
    |> validate_required([:comment])
  end
end
