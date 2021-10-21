defmodule VelocityWeb.Resolvers.Training.TrainingCountries do
  @moduledoc """
    resolver for employee trainings
  """

  alias Velocity.Contexts.Training.TrainingCountries

  def get(args, _) do
    training_countries = TrainingCountries.get_by(id: args.training_country_id)
    {:ok, training_countries}
  end
end
