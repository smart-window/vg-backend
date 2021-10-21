defmodule Velocity.Repo.Migrations.CreateFormFormFields do
  use Ecto.Migration

  def change do
    create table(:form_form_fields) do
      add :form_id, references(:forms, on_delete: :nothing), null: false
      add :form_field_id, references(:form_fields, on_delete: :nothing), null: false
      add :country_id, references(:countries, on_delete: :nothing)

      add :type_override, FormFieldTypeEnum.type()
      add :optional_override, :boolean
      add :source_table_override, :string
      add :source_table_column_override, :string
      add :config_override, :map

      timestamps()
    end

    create(unique_index(:form_form_fields, [:form_id, :form_field_id, :country_id]))
  end
end
