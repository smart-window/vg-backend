defmodule Velocity.Repo.Migrations.CreateForms do
  use Ecto.Migration

  def change do
    create table(:forms) do
      add :slug, :string, null: false
      add :task_id, references(:tasks, on_delete: :nothing)

      timestamps()
    end

    create(unique_index(:forms, [:slug]))
  end
end
