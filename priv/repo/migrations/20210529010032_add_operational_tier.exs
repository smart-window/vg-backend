defmodule Velocity.Repo.Migrations.AddOperationalTier do
  use Ecto.Migration

  def change do
    OperationalTierTypeEnum.create_type()

    alter table(:clients) do
      add :operational_tier, OperationalTierTypeEnum.type()
    end
  end
end
