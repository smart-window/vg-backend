defmodule VelocityWeb.Schema.MeetingTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo

  @desc "meeting"
  object :meeting do
    field :id, :id
    field :description, :string
    field :meeting_date, :date
    field :notes, :string

    field(:users, list_of(:user)) do
      resolve(fn meeting, _args, _info ->
        users = Ecto.assoc(meeting, :users) |> Repo.all()
        {:ok, users}
      end)
    end
  end

  object :client_meeting do
    field :id, :id

    field(:client, :client) do
      resolve(fn client_meeting, _args, _info ->
        client = Ecto.assoc(client_meeting, :client) |> Repo.one()
        {:ok, client}
      end)
    end

    field(:meeting, :meeting) do
      resolve(fn client_meeting, _args, _info ->
        meeting = Ecto.assoc(client_meeting, :meeting) |> Repo.one()
        {:ok, meeting}
      end)
    end
  end
end
