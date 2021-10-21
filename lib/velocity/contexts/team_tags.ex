defmodule Velocity.Contexts.TeamTags do
  @moduledoc """
  The Contexts.TeamTags context.
  """

  import Ecto.Query, warn: false
  alias Velocity.Repo

  alias Velocity.Schema.TeamTag

  @doc """
  Gets a single team_tag.

  Raises if the Team tag does not exist.

  ## Examples

      iex> get_team_tag!(123)
      %TeamTag{}

  """
  def get_team_tag!(id), do: Repo.get!(TeamTag, id) |> Repo.preload([:team, :tag])

  @doc """
  Creates a team_tag.

  ## Examples

      iex> create_team_tag(%{field: value})
      {:ok, %TeamTag{}}

      iex> create_team_tag(%{field: bad_value})
      {:error, ...}

  """
  def create_team_tag(attrs \\ %{}) do
    %TeamTag{}
    |> TeamTag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a TeamTag.

  ## Examples

      iex> delete_team_tag(team_tag)
      {:ok, %TeamTag{}}

      iex> delete_team_tag(team_tag)
      {:error, ...}

  """
  def delete_team_tag(id) do
    %TeamTag{id: id}
    |> Repo.delete()
  end
end
