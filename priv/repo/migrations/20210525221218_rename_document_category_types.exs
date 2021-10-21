defmodule Velocity.Repo.Migrations.RenameDocumentCategoryTypes do
  use Ecto.Migration

  def change do
    rename table(:document_template_categories), :type, to: :entity_type
  end
end
