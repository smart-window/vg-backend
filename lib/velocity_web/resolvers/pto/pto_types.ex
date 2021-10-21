defmodule VelocityWeb.Resolvers.Pto.PtoTypes do
  @moduledoc """
  GQL resolver for pto types
  """

  alias Velocity.Contexts.Pto.PtoTypes

  def get(args, _) do
    {:ok, PtoTypes.get!(String.to_integer(args.id))}
  end

  def create(args, _) do
    PtoTypes.create(args)
  end

  def update(args, _) do
    PtoTypes.update(args)
  end

  def delete(args, _) do
    PtoTypes.delete(String.to_integer(args.id))
  end
end
