defmodule Velocity.Schema.Employment do
  @moduledoc "
    schema for employment
    represents an employment of a job by an employee under a contract
    which is manageable by client managers
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Contract
  alias Velocity.Schema.Country
  alias Velocity.Schema.Employee
  alias Velocity.Schema.EmployeeOnboarding
  alias Velocity.Schema.Job
  alias Velocity.Schema.Partner

  schema "employments" do
    field :effective_date, :date
    field :end_date, :date
    field :end_reason, EmploymentEndReasonEnum
    field :anticipated_start_date, :date
    field :type, EmploymentTypeEnum
    field :status, EmploymentStatusEnum
    field :salesforce_id, :string

    belongs_to :partner, Partner
    belongs_to :employee, Employee
    belongs_to :job, Job
    belongs_to :contract, Contract
    belongs_to :country, Country
    has_many :employee_onboardings, EmployeeOnboarding

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :partner_id,
      :employee_id,
      :job_id,
      :contract_id,
      :country_id,
      :effective_date,
      :anticipated_start_date,
      :type,
      :status,
      :salesforce_id
    ])
    |> validate_required([
      :partner_id,
      :employee_id,
      :job_id,
      :contract_id,
      :country_id
    ])
  end
end
