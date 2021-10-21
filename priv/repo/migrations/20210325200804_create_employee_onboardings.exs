defmodule Velocity.Repo.Migrations.CreateEmployeeOnboardings do
  use Ecto.Migration

  def change do
    create table(:employee_onboardings) do
      add :employment_id, references(:employments), null: false
      add :process_id, references(:processes), null: false
      add :signature_status, :string
      add :immigration, :boolean
      add :benefits, :boolean

      timestamps()
    end
  end
end
