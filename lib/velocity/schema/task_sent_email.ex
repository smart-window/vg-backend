defmodule Velocity.Schema.TaskSentEmail do
  use Ecto.Schema
  import Ecto.Changeset

  schema "task_sent_emails" do
    belongs_to :task, Velocity.Schema.Task
    belongs_to :sent_email, Velocity.Schema.SentEmail

    timestamps()
  end

  @doc false
  def changeset(task_sent_email, attrs) do
    task_sent_email
    |> cast(attrs, [
      :task_id,
      :sent_email_id
    ])
    |> validate_required([
      :task_id,
      :sent_email_id
    ])
  end
end
