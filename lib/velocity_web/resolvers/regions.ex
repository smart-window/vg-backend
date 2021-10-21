defmodule VelocityWeb.Resolvers.Regions do
  @moduledoc """
  GQL resolver for jobs
  """

  alias Velocity.Contexts.Regions

  def get(args, _) do
    {:ok, Regions.get!(String.to_integer(args.id))}
  end

  def create(args, _) do
    Regions.create(args)
  end

  def update(args, _) do
    Regions.update(args)
  end

  def delete(args, _) do
    Regions.delete(String.to_integer(args.id))
  end

  def all(_args, _) do
    {:ok, Regions.all()}
  end
end
