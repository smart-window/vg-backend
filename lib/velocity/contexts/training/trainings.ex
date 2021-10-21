defmodule Velocity.Contexts.Training.Trainings do
  @moduledoc "context for employee training"

  import Ecto.Query

  alias Velocity.Repo
  alias Velocity.Schema.Training.Training
  alias Velocity.Schema.Training.TrainingCountry

  def for_country(country_id) do
    subset =
      from tc in TrainingCountry,
        where: tc.country_id == ^country_id,
        select: tc.training_id

    query =
      from t in Training,
        where: t.id in subquery(subset)

    Repo.all(query)
  end

  def get_by(keyword) do
    Repo.get_by(Training, keyword)
  end

  def create(params) do
    changeset = Training.changeset(%Training{}, params)

    Repo.insert(changeset)
  end

  def update(params) do
    training = get_by(id: params.id)

    changeset = Training.changeset(training, params)

    Repo.update(changeset)
  end

  def delete(training_id) do
    training = get_by(id: training_id)

    Repo.delete(training)
  end
end
