defmodule Velocity.Repo.Migrations.CreateKnowledgeArticles do
  use Ecto.Migration

  def change do
    create table(:knowledge_articles) do
      add :url, :string

      timestamps()
    end
  end
end
