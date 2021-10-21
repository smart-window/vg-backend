defmodule Velocity.Repo.Migrations.ChangeDocTemplateCategoryName do
  use Ecto.Migration

  def change do
    rename table(:document_template_categories), :name, to: :slug
  end
end
