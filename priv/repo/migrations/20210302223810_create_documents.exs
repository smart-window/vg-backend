defmodule Velocity.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :name, :string
      add :action, :string
      add :mime_type, :string
      add :document_template_id, references(:document_templates)
      add :user_id, references(:users)
      add :document_template_category_id, references(:document_template_categories)
      add :example_file_url, :string
      add :status, :string
      add :s3_key, :string
      add :original_filename, :string
      add :original_mime_type, :string

      timestamps()
    end
  end
end
