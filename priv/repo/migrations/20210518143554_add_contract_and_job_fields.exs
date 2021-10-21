defmodule Velocity.Repo.Migrations.AddContractAndJobFields do
  use Ecto.Migration

  def change do
    USMonthEnumEnum.create_type()
    ProbationaryPeriodTermEnum.create_type()
    EmploymentTypeEnum.create_type()
    EmploymentStatusEnum.create_type()

    alter table(:jobs) do
      add :probationary_period_length, :string
      add :probationary_period_term, ProbationaryPeriodTermEnum.type()
    end

    alter table(:contracts) do
      add :payroll_13th_month, USMonthEnumEnum.type()
      add :payroll_14th_month, USMonthEnumEnum.type()
      add :uuid, :string, null: false, default: Ecto.UUID.generate()
    end

    alter table(:employments) do
      add :type, EmploymentTypeEnum.type()
      add :status, EmploymentStatusEnum.type()
    end
  end
end
