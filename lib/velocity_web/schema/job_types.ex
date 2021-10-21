defmodule VelocityWeb.Schema.JobTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo

  @desc "job"
  object :job do
    field :id, :id
    field :title, :string
    field :probationary_period_length, :string
    field :probationary_period_term, :string

    field(:client, :client) do
      resolve(fn client, _args, _info ->
        client = Ecto.assoc(client, :client) |> Repo.one()
        {:ok, client}
      end)
    end
  end
end
