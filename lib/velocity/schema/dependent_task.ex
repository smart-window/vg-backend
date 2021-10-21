defmodule Velocity.Schema.DependentTask do
  @moduledoc """
  A dependent task indicates that the "dependent_task" must be completed before the "task" is allowed to be completed.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Task

  schema "dependent_tasks" do
    belongs_to :task, Task
    belongs_to :dependent_task, Task

    timestamps()
  end

  @doc false
  def changeset(dependent_task, attrs) do
    dependent_task
    |> cast(attrs, [])
    |> validate_required([])
    |> put_assoc(:task, Map.get(attrs, :task), required: true)
    |> put_assoc(:dependent_task, Map.get(attrs, :dependent_task), required: true)
  end
end
