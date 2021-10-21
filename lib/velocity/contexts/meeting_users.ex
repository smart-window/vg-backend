defmodule Velocity.Contexts.MeetingUsers do
  @moduledoc """
  The Contexts.MeetingUsers context.
  """

  import Ecto.Query, warn: false
  alias Velocity.Repo

  alias Velocity.Schema.MeetingUser

  @doc """
  Gets a single meeting_user.

  Raises if the Meeting user does not exist.

  ## Examples

      iex> get_meeting_user!(123)
      %MeetingUser{}

  """
  def get_meeting_user!(id), do: Repo.get!(MeetingUser, id) |> Repo.preload([:meeting, :user])

  @doc """
  Creates a meeting_user.

  ## Examples

      iex> create_meeting_user(%{field: value})
      {:ok, %MeetingUser{}}

      iex> create_meeting_user(%{field: bad_value})
      {:error, ...}

  """
  def create_meeting_user(attrs \\ %{}) do
    %MeetingUser{}
    |> MeetingUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a MeetingUser.

  ## Examples

      iex> delete_meeting_user(meeting_user)
      {:ok, %MeetingUser{}}

      iex> delete_meeting_user(meeting_user)
      {:error, ...}

  """
  def delete_meeting_user(meeting_user_id) do
    %MeetingUser{id: meeting_user_id}
    |> Repo.delete()
  end
end
