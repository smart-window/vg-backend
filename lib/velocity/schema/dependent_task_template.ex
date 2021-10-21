defmodule Velocity.Schema.DependentTaskTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.TaskTemplate

  schema "dependent_task_templates" do
    belongs_to :task_template, TaskTemplate
    belongs_to :dependent_task_template, TaskTemplate

    timestamps()
  end

  @doc false
  def changeset(stage, attrs) do
    stage
    |> cast(attrs, [])
    |> validate_required([])
    |> put_assoc(:task_template, Map.get(attrs, :task_template), required: true)
    |> put_assoc(:dependent_task_template, Map.get(attrs, :dependent_task_template),
      required: true
    )
  end
end
