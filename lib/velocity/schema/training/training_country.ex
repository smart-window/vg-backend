defmodule Velocity.Schema.Training.TrainingCountry do
  @moduledoc """
    Training
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Country
  alias Velocity.Schema.Training.Training

  @fields [
    :training_id,
    :country_id
  ]

  @required_fields [
    :training_id,
    :country_id
  ]

  @derive {Jason.Encoder, only: @fields ++ [:id]}

  schema "training_countries" do
    belongs_to :country, Country
    belongs_to :training, Training

    timestamps()
  end

  def build(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(training_country, attrs) do
    training_country
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def required_fields do
    @required_fields
  end
end
