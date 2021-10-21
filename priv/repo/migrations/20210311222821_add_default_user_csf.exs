defmodule Velocity.Repo.Migrations.AddDefaultUserCsf do
  use Ecto.Migration

  def up do
    execute """
      ALTER TABLE users ALTER COLUMN country_specific_fields SET DEFAULT '{}';
    """

    # backfill existing nulls with default
    execute """
      UPDATE users SET country_specific_fields = '{}' WHERE users.country_specific_fields IS NULL;
    """
  end

  def down do
    execute """
      ALTER TABLE users ALTER COLUMN country_specific_fields DROP DEFAULT;
    """

    execute """
      UPDATE users SET country_specific_fields = null WHERE users.country_specific_fields = '{}';
    """
  end
end
