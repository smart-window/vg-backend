defmodule Velocity.Repo.Migrations.ChangeBirthdateType do
  use Ecto.Migration

  def change do
    execute """
      ALTER TABLE users ALTER COLUMN birth_date TYPE date;
    """
  end
end
