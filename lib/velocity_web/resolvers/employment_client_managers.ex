defmodule VelocityWeb.Resolvers.EmploymentClientManagers do
  @moduledoc """
  GQL resolver for employment to client manager associations
  """

  alias Velocity.Contexts.EmploymentClientManagers

  def get(args, _) do
    {:ok, EmploymentClientManagers.get!(String.to_integer(args.id))}
  end

  def create(args, _) do
    EmploymentClientManagers.create(args)
  end

  def update(args, _) do
    EmploymentClientManagers.update(args)
  end

  def delete(args, _) do
    EmploymentClientManagers.delete(String.to_integer(args.id))
  end
end
