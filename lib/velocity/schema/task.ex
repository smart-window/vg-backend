defmodule Velocity.Schema.Task do
  @moduledoc """
  A task is the unit of work.

  Task completion_type indicated what type of work will be performed

  If the compeletion_type is 'check_off" the user simply indicates the task was performed.
  Additional task types will be added to include custom front-end pages as well as custom backend logic
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Velocity.Schema.Process
  alias Velocity.Schema.Service
  alias Velocity.Schema.Stage
  alias Velocity.Schema.Task
  alias Velocity.Schema.TaskAssignment
  alias Velocity.Schema.TaskComment
  alias Velocity.Schema.TaskSentEmail
  alias Velocity.Schema.TaskTemplate

  schema "tasks" do
    belongs_to :process, Process
    belongs_to :stage, Stage
    belongs_to :service, Service
    has_many :task_assignments, TaskAssignment
    has_many :task_comments, TaskComment

    has_many :task_sent_emails, TaskSentEmail
    has_many :sent_emails, through: [:task_sent_emails, :sent_email]

    many_to_many :dependent_tasks, Task,
      join_through: "dependent_tasks",
      join_keys: [task_id: :id, dependent_task_id: :id]

    belongs_to :task_template, TaskTemplate

    field :order, :integer
    field :completion_type, :string
    field :status, :string
    field :type, :string
    field :name, :string, virtual: true
    field :context, :string, virtual: true
    field :knowledge_articles, :map, virtual: true

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :order,
      :completion_type,
      :status,
      :type,
      :process_id,
      :service_id,
      :stage_id,
      :task_template_id
    ])
    |> validate_required([:completion_type, :status])
    |> validate_inclusion(:completion_type, ["check_off", "auto", "custom"])
    |> validate_inclusion(:status, ["not_started", "in_progress", "failed", "completed"])
  end
end
