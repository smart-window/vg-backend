defmodule VelocityWeb.Resolvers.Jobs do
  @moduledoc """
  GQL resolver for jobs
  """

  alias Velocity.Contexts.Jobs
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.Employment

  import Ecto.Query

  def get(args, %{context: %{current_user: current_user}}) do
    employment =
      Repo.one!(
        from(e in Employment,
          join: em in assoc(e, :employee),
          where: e.job_id == ^String.to_integer(args.id) and em.user_id == ^current_user.id
        )
      )

    if Users.is_user_internal(current_user) || !is_nil(employment) do
      {:ok, Jobs.get!(String.to_integer(args.id))}
    else
      {:error, "User #{current_user.id} is not authorized to get job #{args.id}"}
    end
  end

  def create(args, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      Jobs.create(args)
    else
      {:error, "User #{current_user.id} is not authorized to create a job"}
    end
  end

  def update(args, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      Jobs.update(args)
    else
      {:error, "User #{current_user.id} is not authorized to edit job #{args.id}"}
    end
  end

  def delete(args, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      Jobs.delete(String.to_integer(args.id))
    else
      {:error, "USer #{current_user.id} cannot be delete job #{args.id}"}
    end
  end
end
