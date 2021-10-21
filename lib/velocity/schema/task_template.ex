defmodule Velocity.Schema.TaskTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Service
  alias Velocity.Schema.StageTemplate
  alias Velocity.Schema.TaskTemplate
  alias Velocity.Schema.TaskTemplateRole
  alias Velocity.Schema.TaskTemplateRoleNotification

  @fields [
    :name,
    :type,
    :order,
    :context,
    :completion_type,
    :knowledge_article_search_terms,
    :knowledge_article_urls
  ]
  @required_fields [:name, :order, :completion_type]

  @task_types %{
    email_template: "email_template",
    instructions: "instructions",
    auto: "auto",
    create_cxp_employee: "create_cxp_employee",
    pega_netsuite_client_creation: "pega_netsuite_client_creation",
    pega_netsuite_employee_creation: "pega_netsuite_employee_creation",
    invoice_approval: "invoice_approval",
    background_check: "background_check",
    payment_verification: "payment_verification",
    meeting_set: "meeting_set",
    cam_tier_assignment: "cam_tier_assignment"
  }

  schema "task_templates" do
    field :context, :map
    field :name, :string
    field :type, :string
    field :order, :integer
    field :completion_type, :string
    belongs_to :stage_template, StageTemplate
    belongs_to :service, Service

    has_many :task_template_role_notifications, TaskTemplateRoleNotification
    has_many :task_template_roles, TaskTemplateRole
    has_many :roles, through: [:task_template_roles, :role]

    many_to_many :dependent_task_templates, TaskTemplate,
      join_through: "dependent_task_templates",
      join_keys: [task_template_id: :id, dependent_task_template_id: :id]

    field :knowledge_article_urls, {:array, :string}
    field :knowledge_article_search_terms, {:array, :string}

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:completion_type, ["check_off", "auto", "custom"])
    |> put_assoc(:stage_template, Map.get(attrs, :stage_template), required: true)
    |> put_assoc(:service, Map.get(attrs, :service), required: true)
  end

  def task_types, do: Map.values(@task_types)

  def task_type(type), do: Map.fetch!(@task_types, type)
end
