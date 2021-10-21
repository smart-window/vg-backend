defmodule Velocity.Schema.TaskAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Role
  alias Velocity.Schema.Task
  alias Velocity.Schema.User

  schema "task_assignments" do
    belongs_to :task, Task
    belongs_to :user, User
    belongs_to :role, Role

    field :read_only, :boolean

    timestamps()
  end

  @doc false
  def changeset(task_assignment, attrs) do
    task_assignment
    |> cast(attrs, [:task_id, :user_id, :role_id])
    |> validate_required([])
  end
end
