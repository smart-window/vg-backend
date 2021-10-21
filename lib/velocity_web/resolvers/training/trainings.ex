defmodule VelocityWeb.Resolvers.Training.Trainings do
  @moduledoc """
    resolver for trainings
  """

  alias Velocity.Contexts.Employments
  alias Velocity.Contexts.Training.Trainings

  def for_users_country(_args, %{context: %{current_user: current_user}}) do
    employment = Employments.get_for_user(current_user.id)

    country_id =
      cond do
        employment != nil ->
          employment.country_id

        current_user.work_address != nil ->
          current_user.work_address.country_id

        true ->
          current_user.nationality_id
      end

    if country_id == nil do
      {:error, "You need a country of employment to access trainings."}
    else
      {:ok, Trainings.for_country(country_id)}
    end
  end

  def for_country(args, _) do
    country_id = Map.get(args, :country_id)
    {:ok, Trainings.for_country(country_id)}
  end

  def get(args, _) do
    training = Trainings.get_by(id: args.training_id)
    {:ok, training}
  end

  def create_training(args, _) do
    training_params = %{
      name: args.name,
      description: args.description,
      bundle_url: args.bundle_url
    }

    case Trainings.create(training_params) do
      {:ok, new_training} ->
        {:ok, new_training}

      {:error, error} ->
        {:error, error}
    end
  end

  def update_training(args, _) do
    params = %{
      id: args.id,
      name: args.name,
      description: args.description,
      bundle_url: args.bundle_url
    }

    case Trainings.update(params) do
      {:error, error} ->
        {:error, error}
    end
  end

  def delete_training(args, _) do
    case Trainings.delete(args.id) do
      {:error, error} ->
        {:error, error}
    end
  end
end
