defmodule Velocity.Repo.Migrations.AddClientStateToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :client_state, :map
    end
  end
end
