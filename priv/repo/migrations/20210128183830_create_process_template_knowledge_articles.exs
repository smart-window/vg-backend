defmodule Velocity.Repo.Migrations.CreateProcessTemplateKnowledgeArticles do
  use Ecto.Migration

  def change do
    create table(:process_template_knowledge_articles, primary_key: false) do
      add :process_template_id, references(:process_templates)
      add :knowledge_article_id, references(:knowledge_articles)
    end
  end
end
