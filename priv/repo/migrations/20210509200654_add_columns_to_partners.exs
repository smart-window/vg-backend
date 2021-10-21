defmodule Velocity.Repo.Migrations.AddColumnsToPartners do
  use Ecto.Migration

  def change do
    PartnerTypeEnum.create_type()

    alter table(:partners) do
      add :type, PartnerTypeEnum.type()
    end
  end
end
