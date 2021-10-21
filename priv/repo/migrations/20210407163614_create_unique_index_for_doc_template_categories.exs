defmodule Velocity.Repo.Migrations.CreateUniqueIndexForDocTemplateCategories do
  use Ecto.Migration

  def change do
    create(unique_index(:document_template_categories, [:name]))
  end
end
