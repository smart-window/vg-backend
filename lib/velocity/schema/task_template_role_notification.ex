defmodule Velocity.Schema.TaskTemplateRoleNotification do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Role
  alias Velocity.Schema.TaskTemplate

  schema "task_template_role_notifications" do
    belongs_to :task_template, TaskTemplate
    belongs_to :role, Role

    timestamps()
  end

  @doc false
  def changeset(task_template_role_notifications, attrs) do
    task_template_role_notifications
    |> cast(attrs, [])
    |> validate_required([])
  end
end
