defmodule Velocity.Repo.Migrations.CreateDocumentTemplates do
  use Ecto.Migration

  def change do
    create table(:document_templates) do
      add :name, :string
      add :mime_type, :string
      add :document_template_category_id, references(:document_template_categories)
      add :client_id, references(:clients)
      add :country_id, references(:countries)
      add :action, :string
      add :instructions, :text
      add :example_file_url, :string

      timestamps()
    end
  end
end
