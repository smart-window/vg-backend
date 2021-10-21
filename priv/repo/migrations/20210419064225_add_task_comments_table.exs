defmodule Velocity.Repo.Migrations.AddTaskCommentsTable do
  use Ecto.Migration

  def change do
    TaskCommentVisibilityType.create_type()

    create table(:task_comments) do
      add :task_id, references(:tasks), null: false
      add :user_id, references(:users), null: false
      add :comment, :text, null: false
      add :visibility_type, TaskCommentVisibilityType.type(), null: false

      timestamps()
    end
  end
end
