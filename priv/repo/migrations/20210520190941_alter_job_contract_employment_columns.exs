defmodule Velocity.Repo.Migrations.AlterJobContractEmploymentColumns do
  use Ecto.Migration

  def up do
    execute """
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    """

    execute """
      UPDATE contracts SET uuid = uuid_generate_v4();
    """

    alter table(:contracts) do
      modify :uuid, :string, default: fragment("uuid_generate_v4()"), null: false
    end

    alter table(:jobs) do
      remove :probationary_period_length
      add :probationary_period_length, :float
    end
  end

  def down do
    alter table(:contracts) do
      modify :uuid, :string, null: false, default: Ecto.UUID.generate()
    end

    alter table(:jobs) do
      modify :probationary_period_length, :string
    end
  end
end
