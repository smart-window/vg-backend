defmodule Velocity.Repo.Migrations.AddTermationEnums do
  use Ecto.Migration

  def change do
    TerminationReasonEnum.create_type()
    TerminationSubReasonEnum.create_type()

    alter table(:contracts) do
      remove :termination_reason
      remove :termination_sub_reason

      add :termination_reason, TerminationReasonEnum.type()
      add :termination_sub_reason, TerminationSubReasonEnum.type()
    end
  end
end
