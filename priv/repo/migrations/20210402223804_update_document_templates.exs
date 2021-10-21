defmodule Velocity.Repo.Migrations.UpdateDocumentTemplates do
  use Ecto.Migration

  def change do
    alter table(:document_templates) do
      add :file_type, :string
      add :partner_id, references(:partners)
      add :required, :boolean
    end

    rename table(:document_templates), :mime_type, to: :example_file_mime_type
  end
end
