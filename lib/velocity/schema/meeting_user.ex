defmodule Velocity.Schema.MeetingUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Meeting
  alias Velocity.Schema.User

  schema "meeting_users" do
    belongs_to :meeting, Meeting
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(meeting_user, attrs) do
    meeting_user
    |> cast(attrs, [])
    |> put_assoc(:meeting, Map.get(attrs, :meeting), required: true)
    |> put_assoc(:user, Map.get(attrs, :user), required: true)
  end
end
