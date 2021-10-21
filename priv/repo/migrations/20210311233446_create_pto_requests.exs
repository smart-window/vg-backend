defmodule Velocity.Repo.Migrations.CreatePtoRequests do
  use Ecto.Migration

  def change do
    PTODecisionEnum.create_type()

    create table(:pto_requests) do
      add :employment_id, references(:employments), null: false
      add :request_comment, :string, size: 4096
      add :decision, PTODecisionEnum.type()
      add :decided_by_user_id, references(:users)
      add :decision_comment, :string, size: 4096

      add :pega_pk, :string
      add :pega_ak, :string

      timestamps()
    end
  end
end
