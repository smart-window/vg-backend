defmodule Velocity.Repo.Migrations.AddPegaKeysToLevels do
  use Ecto.Migration

  def change do
    alter table(:levels) do
      add :pega_pk, :string
      add :pega_ak, :string
    end
  end
end
