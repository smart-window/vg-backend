defmodule Velocity.Repo.Migrations.AddHalfDayToPtoRequestDaySlotEnum do
  use Ecto.Migration

  def up do
    execute """
      alter type pto_slot add value if not exists 'half_day' after 'all_day';
    """
  end

  def down do
    execute """
      delete from pg_enum where enumlabel = 'half_day' and enumtypid = (select oid from pg_type where typname = 'pto_slot');
    """
  end
end
