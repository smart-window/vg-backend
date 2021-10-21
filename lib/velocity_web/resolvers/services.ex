defmodule VelocityWeb.Resolvers.Services do
  @moduledoc """
    resolver for services
  """

  alias Velocity.Contexts.Services

  def all(_args, _) do
    {:ok, Services.list_services()}
  end
end
