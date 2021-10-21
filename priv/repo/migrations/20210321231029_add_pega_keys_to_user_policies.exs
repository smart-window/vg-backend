defmodule Velocity.Repo.Migrations.AddPegaKeysToUserPolicies do
  use Ecto.Migration

  def change do
    alter table(:user_policies) do
      add :pega_pk, :string
      add :pega_ak, :string
    end
  end
end
