defmodule Velocity.Schema.Training.Training do
  @moduledoc """
    Training
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Training.EmployeeTraining
  alias Velocity.Schema.Training.TrainingCountry

  @fields [
    :name,
    :description,
    :bundle_url
  ]

  @required_fields [
    :name,
    :bundle_url
  ]

  @derive {Jason.Encoder, only: @fields ++ [:id]}

  schema "trainings" do
    field :name, :string
    field :description, :string
    field :bundle_url, :string
    has_many :employee_trainings, EmployeeTraining
    has_many :training_countries, TrainingCountry

    timestamps()
  end

  def build(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(training, attrs) do
    training
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def required_fields do
    @required_fields
  end
end
