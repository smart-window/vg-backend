defmodule Velocity.Schema.KnowledgeArticle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "knowledge_articles" do
    field :url, :string

    timestamps()
  end

  @doc false
  def changeset(knowledge_articles, attrs) do
    knowledge_articles
    |> cast(attrs, [:url])
    |> validate_required([:url])
  end
end
