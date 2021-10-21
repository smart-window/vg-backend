defmodule Velocity.Repo.Migrations.AddUserSettings do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :settings, :map, default: %{language: "en"}
    end
  end
end
