defmodule Velocity.Contexts.Training.TrainingCountries do
  @moduledoc "context for training_country countires"

  alias Velocity.Repo
  alias Velocity.Schema.Training.TrainingCountry

  def get_by(keyword) do
    Repo.get_by(TrainingCountry, keyword)
  end

  def create(params) do
    changeset = TrainingCountry.changeset(%TrainingCountry{}, params)

    Repo.insert(changeset)
  end

  def update(params) do
    training_country = get_by(id: params.training_country_id)

    changeset = TrainingCountry.changeset(training_country, params)

    Repo.update(changeset)
  end

  def delete(training_country_id) do
    training_country = get_by(id: training_country_id)

    Repo.delete(training_country)
  end
end
