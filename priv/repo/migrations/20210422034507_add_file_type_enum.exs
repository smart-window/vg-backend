defmodule Velocity.Repo.Migrations.AddFileTypeEnum do
  use Ecto.Migration

  def change do
    DocumentFileTypeEnum.create_type()

    execute """
     alter table documents alter column file_type type document_file_type USING file_type::document_file_type
    """

    DocumentTemplateFileTypeEnum.create_type()

    execute """
     alter table document_templates alter column file_type type document_template_file_type USING file_type::document_template_file_type
    """
  end
end
