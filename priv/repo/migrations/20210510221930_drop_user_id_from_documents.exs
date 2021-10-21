defmodule Velocity.Repo.Migrations.DropUserIdFromDocuments do
  use Ecto.Migration

  def change do
    alter table(:documents) do
      remove(:user_id)
    end
  end
end
