defmodule Velocity.Repo.Migrations.AddOverdueTrainingStatus do
  use Ecto.Migration

  def up do
    execute """
      alter type training_status add value if not exists 'overdue' after 'completed';
    """
  end

  def down do
    execute """
      delete from pg_enum where enumlabel = 'overdue' and enumtypid = (select oid from pg_type where typname = 'training_status');
    """
  end
end
