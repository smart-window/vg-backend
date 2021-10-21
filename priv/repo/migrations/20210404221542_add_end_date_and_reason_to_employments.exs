defmodule Velocity.Repo.Migrations.AddEndDateAndReasonToEmployments do
  use Ecto.Migration

  def change do
    EmploymentEndReasonEnum.create_type()

    alter table(:employments) do
      add :end_date, :date
      add :end_reason, EmploymentEndReasonEnum.type()
    end
  end
end
