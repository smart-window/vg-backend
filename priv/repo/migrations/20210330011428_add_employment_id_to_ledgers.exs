defmodule Velocity.Repo.Migrations.AddEmploymentIdToLedgers do
  use Ecto.Migration

  def change do
    alter table(:ledgers) do
      add :employment_id, references(:employments)
    end
  end
end
