defmodule Velocity.Schema.StageTemplateKnowledgeArticle do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.KnowledgeArticle
  alias Velocity.Schema.StageTemplate
  alias Velocity.Utils.Changesets, as: Utils

  schema "stage_template_knowledge_articles" do
    belongs_to :stage_template, StageTemplate
    belongs_to :knowledge_article, KnowledgeArticle
    timestamps()
  end

  @doc false
  def changeset(stage, attrs) do
    stage
    |> cast(attrs, [])
    |> validate_required([])
    |> Utils.maybe_put_assoc(:stage_template, attrs)
    |> Utils.maybe_put_assoc(:knowledge_article, attrs)
  end
end
