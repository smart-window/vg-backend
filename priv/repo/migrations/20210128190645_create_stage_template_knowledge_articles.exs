defmodule Velocity.Repo.Migrations.CreateStageTemplateKnowledgeArticles do
  use Ecto.Migration

  def change do
    create table(:stage_template_knowledge_articles, primary_key: false) do
      add :stage_template_id, references(:stage_templates)
      add :knowledge_article_id, references(:knowledge_articles)
    end
  end
end
