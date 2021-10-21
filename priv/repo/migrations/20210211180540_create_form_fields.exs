defmodule Velocity.Repo.Migrations.CreateFormFields do
  use Ecto.Migration

  def change do
    FormFieldTypeEnum.create_type()

    create table(:form_fields) do
      add :slug, :string, null: false
      add :type, FormFieldTypeEnum.type(), null: false
      add :optional, :boolean
      add :source_table, :string, null: false
      add :source_table_column, :string, null: false
      add :config, :map

      timestamps()
    end

    create(unique_index(:form_fields, [:slug]))
  end
end
