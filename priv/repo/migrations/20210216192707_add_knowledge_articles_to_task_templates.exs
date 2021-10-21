defmodule Velocity.Repo.Migrations.AddKnowledgeArticlesToTaskTemplates do
  use Ecto.Migration

  def change do
    alter table(:task_templates) do
      add :knowledge_article_urls, {:array, :string}
      add :knowledge_article_search_terms, {:array, :string}
    end
  end
end
