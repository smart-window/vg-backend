defmodule Velocity.Schema.Training.EmployeeTraining do
  @moduledoc """
    Accrual polices are a set of rules that dictate how PTO accrues over time.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Training.Training
  alias Velocity.Schema.User

  @fields [
    :due_date,
    :status,
    :completed_date,
    :user_id,
    :training_id
  ]

  @required_fields [
    :status,
    :user_id,
    :training_id
  ]

  @derive {Jason.Encoder, only: @fields ++ [:id]}

  schema "employee_trainings" do
    field :due_date, :date
    field :status, TrainingStatusEnum
    field :completed_date, :date

    belongs_to :training, Training
    belongs_to :user, User

    timestamps()
  end

  def build(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(employee_training, attrs) do
    employee_training
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def required_fields do
    @required_fields
  end
end
