defmodule Velocity.Repo.Migrations.CreateTaskTemplateKnowledgeArticles do
  use Ecto.Migration

  def change do
    create table(:task_template_knowledge_articles, primary_key: false) do
      add :task_template_id, references(:task_templates)
      add :knowledge_article_id, references(:knowledge_articles)
    end
  end
end
