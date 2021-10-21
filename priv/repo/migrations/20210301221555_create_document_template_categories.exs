defmodule Velocity.Repo.Migrations.CreateDocumentCategories do
  use Ecto.Migration

  def change do
    create table(:document_template_categories) do
      add :name, :string

      timestamps()
    end
  end
end
