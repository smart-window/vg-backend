defmodule Velocity.Schema.TaskTemplateRole do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Role
  alias Velocity.Schema.TaskTemplate

  schema "task_template_roles" do
    belongs_to :task_template, TaskTemplate
    belongs_to :role, Role

    timestamps()
  end

  @doc false
  def changeset(task_template_roles, attrs) do
    task_template_roles
    |> cast(attrs, [])
    |> validate_required([])
    |> put_assoc(:task_template, Map.get(attrs, :task_template), required: true)
    |> put_assoc(:role, Map.get(attrs, :role), required: true)
  end
end
