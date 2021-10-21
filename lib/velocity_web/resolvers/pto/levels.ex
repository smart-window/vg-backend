defmodule VelocityWeb.Resolvers.Pto.Levels do
  @moduledoc """
    resolver for accrual policy levels
  """

  alias Velocity.Contexts.Pto.Levels

  def create_level(args, _) do
    Levels.create_level(args)
  end

  def update_level(args, _) do
    Levels.update_level(args.id, Map.delete(args, :id))
  end

  def delete_level(args, _) do
    Levels.delete_level(args)
  end
end
