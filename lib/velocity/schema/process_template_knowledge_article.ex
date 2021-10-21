defmodule Velocity.Schema.ProcessTemplateKnowledgeArticle do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.KnowledgeArticle
  alias Velocity.Schema.ProcessTemplate
  alias Velocity.Utils.Changesets, as: Utils

  schema "process_template_knowledge_articles" do
    belongs_to :process_template, ProcessTemplate
    belongs_to :knowledge_article, KnowledgeArticle
  end

  @doc false
  def changeset(process, attrs) do
    process
    |> cast(attrs, [])
    |> validate_required([])
    |> Utils.maybe_put_assoc(:process_template, attrs)
    |> Utils.maybe_put_assoc(:knowledge_article, attrs)
  end
end
