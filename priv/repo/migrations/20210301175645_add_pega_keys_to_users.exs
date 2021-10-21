defmodule Velocity.Repo.Migrations.AddPegaKeysToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pega_pk, :string
      add :pega_ak, :string
    end
  end
end
