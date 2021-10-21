defmodule Velocity.Repo.Migrations.AddPegaKeysToUserRoles do
  use Ecto.Migration

  def change do
    alter table(:user_roles) do
      add :pega_pk, :string
      add :pega_ak, :string
    end
  end
end
