defmodule Velocity.Repo.Migrations.AddStartDateToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :start_date, :date
    end
  end
end
