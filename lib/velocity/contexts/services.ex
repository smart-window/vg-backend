defmodule Velocity.Contexts.Services do
  @moduledoc """
  The Contexts.Services context.
  """

  import Ecto.Query, warn: false
  alias Velocity.Repo

  alias Velocity.Schema.Service

  @doc """
  Returns the list of services.

  ## Examples

      iex> list_services()
      [%Service{}, ...]

  """
  def list_services do
    Repo.all(Service)
  end
end
