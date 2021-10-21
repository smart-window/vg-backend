defmodule VelocityWeb.Resolvers.Employments do
  @moduledoc """
  GQL resolver for employments
  """

  alias Velocity.Contexts.Employments
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.Employment

  import Ecto.Query

  def get(args, %{context: %{current_user: current_user}}) do
    employment =
      Repo.one!(
        from(e in Employment,
          join: em in assoc(e, :employee),
          where: e.id == ^String.to_integer(args.id) and em.user_id == ^current_user.id
        )
      )

    if Users.is_user_internal(current_user) || !is_nil(employment) do
      {:ok, employment}
    else
      {:error, "User #{current_user.id} is not authorized to get employment #{args.id}"}
    end
  end

  def create(args, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      Employments.create(args)
    else
      {:error, "User #{current_user.id} is not authorized to create an employment"}
    end
  end

  def update(args, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      Employments.update(args)
    else
      {:error, "User #{current_user.id} is not authorized to edit employment #{args.id}"}
    end
  end

  def delete(args, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      Employments.delete(String.to_integer(args.id))
    else
      {:error, "User #{current_user.id} is not authorized to delete employment #{args.id}"}
    end
  end
end
