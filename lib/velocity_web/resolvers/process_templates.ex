defmodule VelocityWeb.Resolvers.ProcessTemplates do
  @moduledoc """
    resolver for process templates
  """

  alias Velocity.Contexts.ProcessTemplates

  def all(_args, _) do
    {:ok, ProcessTemplates.list_process_templates()}
  end
end
