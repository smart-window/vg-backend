defmodule Velocity.Repo.Migrations.DropUniqueIdxUsersEmail do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(:users, [:email])
  end
end
