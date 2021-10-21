defmodule Velocity.Repo.Migrations.AddTerminationContractData do
  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add :termination_date, :date
      add :termination_reason, :string
      add :termination_sub_reason, :string
    end
  end
end
