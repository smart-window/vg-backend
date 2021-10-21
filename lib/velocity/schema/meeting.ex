defmodule Velocity.Schema.Meeting do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.MeetingUser

  schema "meetings" do
    field :description, :string
    field :meeting_date, :date
    field :notes, :string

    has_many :meeting_users, MeetingUser
    has_many :users, through: [:meeting_users, :user]

    timestamps()
  end

  @doc false
  def changeset(meeting, attrs) do
    meeting
    |> cast(attrs, [:meeting_date, :description, :notes])
    |> validate_required([:meeting_date, :description, :notes])
  end
end
