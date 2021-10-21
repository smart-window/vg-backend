defmodule Velocity.Schema.StageTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.KnowledgeArticle
  alias Velocity.Schema.ProcessTemplate
  alias Velocity.Schema.TaskTemplate
  alias Velocity.Utils.Changesets, as: Utils

  schema "stage_templates" do
    field :name, :string
    field :order, :integer
    belongs_to :process_template, ProcessTemplate
    has_many :task_templates, TaskTemplate

    many_to_many :knowledge_articles, KnowledgeArticle,
      join_through: "stage_template_knowledge_articles"

    timestamps()
  end

  @doc false
  def changeset(stage, attrs) do
    stage
    |> cast(attrs, [:order, :name])
    |> validate_required([:order, :name])
    |> Utils.maybe_put_assoc(:process_template, attrs)
  end
end
