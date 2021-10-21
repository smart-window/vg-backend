defmodule Velocity.Schema.ProcessTemplate do
  @moduledoc """
  A process template defines a set of template stages (swimlanes)
  and template tasks (cards) to be completed.

  Each task relates to a service and a process becomes an instance of a process template.

  For example. The "onboarding" process might include different tasks depending on
  which services the client buys. If a client does not have our Payroll product then
  the process instances for this template type would not include tasks related to payroll.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.KnowledgeArticle
  alias Velocity.Schema.StageTemplate

  schema "process_templates" do
    field :type, :string
    has_many :stage_templates, StageTemplate

    many_to_many :knowledge_articles, KnowledgeArticle,
      join_through: "process_template_knowledge_articles"

    timestamps()
  end

  @doc false
  def changeset(process_template, attrs) do
    process_template
    |> cast(attrs, [:type])
    |> validate_required([:type])
  end
end
