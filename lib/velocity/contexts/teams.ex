defmodule Velocity.Contexts.Teams do
  @moduledoc """
  The Contexts.Teams context.
  """

  import Ecto.Query, warn: false
  alias Velocity.Repo

  alias Velocity.Schema.Team

  @doc """
  Returns the list of teams.

  ## Examples

      iex> list_teams()
      [%Team{}, ...]

  """
  def list_teams do
    Repo.all(Team)
  end

  @doc """
  Gets a single team.

  Raises if the Team does not exist.

  ## Examples

      iex> get_team!(123)
      %Team{}

  """
  def get_team!(id), do: Repo.get!(Team, id)

  @doc """
  Creates a team.

  ## Examples

      iex> create_team(%{field: value})
      {:ok, %Team{}}

      iex> create_team(%{field: bad_value})
      {:error, ...}

  """
  def create_team(attrs \\ %{}) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a team.

  ## Examples

      iex> update_team(id, %{field: new_value})
      {:ok, %Team{}}

      iex> update_team(id, %{field: bad_value})
      {:error, ...}

  """
  def update_team(id, attrs) do
    Repo.get!(Team, id)
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Team.

  ## Examples

      iex> delete_team(team)
      {:ok, %Team{}}

      iex> delete_team(team)
      {:error, ...}

  """
  def delete_team(id) do
    %Team{id: id}
    |> Repo.delete()
  end
end
