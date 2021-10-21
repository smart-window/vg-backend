defmodule Velocity.Repo.Migrations.DeleteTaskTemplateKnowledgeArticles do
  use Ecto.Migration

  def change do
    drop_if_exists table(:task_template_knowledge_articles)
  end
end
