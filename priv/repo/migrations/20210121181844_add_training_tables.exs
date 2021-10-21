defmodule Velocity.Repo.Migrations.AddTrainingTables do
  use Ecto.Migration

  def change do
    TrainingStatusEnum.create_type()

    create table(:trainings) do
      add :name, :string
      add :description, :string
      add :bundle_url, :string
      timestamps()
    end

    create table(:employee_trainings) do
      add :training_id, references(:trainings)
      add :user_id, references(:users)
      add :due_date, :date
      add :status, TrainingStatusEnum.type()
      add :completed_date, :date
      timestamps()
    end

    create table(:training_countries) do
      add :country_id, references(:countries)
      add :training_id, references(:trainings)
      timestamps()
    end
  end
end
