defmodule Velocity.Repo.Migrations.AddBooleanToFormFieldTypes do
  use Ecto.Migration

  def up do
    execute """
      alter type form_field_type add value if not exists 'boolean' before 'date';
    """
  end

  def down do
    execute """
      delete from pg_enum where enumlabel = 'boolean' and enumtypid = (select oid from pg_type where typname = 'form_field_type');
    """
  end
end
