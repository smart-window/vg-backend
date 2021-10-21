defmodule Velocity.Schema.ClientManager do
  @moduledoc "
    schema for client managers
    represents client employees that can manage employments
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Client
  alias Velocity.Schema.ClientManager
  alias Velocity.Schema.User

  schema "client_managers" do
    field :job_title, :string
    field :email, :string

    belongs_to :user, User
    belongs_to :client, Client
    belongs_to :reports_to, ClientManager

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :user_id,
      :client_id,
      :reports_to_id,
      :job_title,
      :email
    ])
    |> validate_required([
      :user_id,
      :client_id
    ])
  end
end
