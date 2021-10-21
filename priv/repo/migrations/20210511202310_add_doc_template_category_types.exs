defmodule Velocity.Repo.Migrations.AddDocTemplateCategoryTypes do
  use Ecto.Migration

  def change do
    DocumentTemplateCategoryTypeEnum.create_type()

    alter table(:document_template_categories) do
      add :type, DocumentTemplateCategoryTypeEnum.type()
    end
  end
end
