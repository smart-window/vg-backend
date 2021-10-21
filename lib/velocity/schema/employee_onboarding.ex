defmodule Velocity.Schema.EmployeeOnboarding do
  @moduledoc "
    schema for employee_onboarding
    represents an employee_onboarding of a job by an employee under a contract
    which is manageable by client managers
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Employment
  alias Velocity.Schema.Process

  schema "employee_onboardings" do
    field :signature_status, :string
    field :immigration, :boolean
    field :benefits, :boolean

    belongs_to :employment, Employment
    belongs_to :process, Process

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :employment_id,
      :process_id,
      :signature_status,
      :immigration,
      :benefits
    ])
    |> validate_required([
      :employment_id,
      :process_id
    ])
  end
end
