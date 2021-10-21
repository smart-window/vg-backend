defmodule Velocity.Repo.Migrations.RenameFormFieldsSourceColumn do
  use Ecto.Migration

  def change do
    rename table("form_fields"), :source_table_column, to: :source_table_field

    rename table("form_form_fields"), :source_table_column_override,
      to: :source_table_field_override
  end
end
