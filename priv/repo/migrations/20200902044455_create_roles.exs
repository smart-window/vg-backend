defmodule Velocity.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :slug, :string, null: false
      add :description, :string
      add :okta_group_slug, :string, null: false
      add :is_super_admin, :boolean

      timestamps()
    end

    create(unique_index(:roles, :slug))
    create(unique_index(:roles, :okta_group_slug))
  end
end
