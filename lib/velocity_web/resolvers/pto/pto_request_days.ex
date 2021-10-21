defmodule VelocityWeb.Resolvers.Pto.PtoRequestDays do
  @moduledoc """
  GQL resolver for pto request days
  """

  alias Velocity.Contexts.Pto.PtoRequestDays

  def get(args, _) do
    {:ok, PtoRequestDays.get!(String.to_integer(args.id))}
  end

  def create(args, _) do
    PtoRequestDays.create(args)
  end

  def update(args, _) do
    PtoRequestDays.update(args)
  end

  def delete(args, _) do
    PtoRequestDays.delete(String.to_integer(args.id))
  end
end
