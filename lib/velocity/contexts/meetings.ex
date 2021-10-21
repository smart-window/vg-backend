defmodule Velocity.Contexts.Meetings do
  @moduledoc """
  The Contexts.Meetings context.
  """

  import Ecto.Query, warn: false
  alias Velocity.Repo
  alias Velocity.Schema.ClientMeeting
  alias Velocity.Schema.Meeting

  @doc """
  Returns the list of meetings.

  ## Examples

      iex> list_meetings()
      [%Meeting{}, ...]

  """
  def list_meetings do
    Repo.all(Meeting)
  end

  @doc """
  Gets a single meeting.

  Raises if the Meeting does not exist.

  ## Examples

      iex> get_meeting!(123)
      %Meeting{}

  """
  def get_meeting!(id), do: Repo.get!(Meeting, id)

  @doc """
  Creates a meeting.

  ## Examples

      iex> create_meeting(%{field: value})
      {:ok, %Meeting{}}

      iex> create_meeting(%{field: bad_value})
      {:error, ...}

  """
  def create_meeting(attrs \\ %{}) do
    %Meeting{}
    |> Meeting.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a meeting.

  ## Examples

      iex> update_meeting(meeting, %{field: new_value})
      {:ok, %Meeting{}}

      iex> update_meeting(meeting, %{field: bad_value})
      {:error, ...}

  """
  def update_meeting(id, attrs) do
    Repo.get!(Meeting, id)
    |> Meeting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Meeting.

  ## Examples

      iex> delete_meeting(meeting.id)
      {:ok, %Meeting{}}

      iex> delete_meeting(meeting.id)
      {:error, ...}

  """
  def delete_meeting(id) do
    %Meeting{id: id}
    |> Repo.delete()
  end

  def upsert_client_meeting(args) do
    if id = Map.get(args, :id) do
      client_meeting = Repo.get!(ClientMeeting, id) |> Repo.preload(:meeting)
      Meeting.changeset(client_meeting.meeting, args) |> Repo.update()
      {:ok, client_meeting}
    else
      {:ok, meeting} = Meeting.changeset(%Meeting{}, args) |> Repo.insert()

      ClientMeeting.changeset(
        %ClientMeeting{},
        %{client_id: args.client_id, meeting_id: meeting.id}
      )
      |> Repo.insert()
    end
  end

  def delete_client_meeting(id) do
    %ClientMeeting{id: id} |> Repo.delete()
  end
end
