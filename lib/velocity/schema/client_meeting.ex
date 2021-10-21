defmodule Velocity.Schema.ClientMeeting do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Client
  alias Velocity.Schema.Meeting

  schema "client_meetings" do
    belongs_to :client, Client
    belongs_to :meeting, Meeting

    timestamps()
  end

  @doc false
  def changeset(client_meeting, attrs) do
    client_meeting
    |> cast(attrs, [:client_id, :meeting_id])
    |> validate_required([:client_id, :meeting_id])
  end
end
