defmodule Velocity.Schema.ProcessService do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Service

  schema "process_services" do
    field :process_id, :id
    belongs_to :service, Service

    timestamps()
  end

  @doc false
  def changeset(process_services, attrs) do
    process_services
    |> cast(attrs, [])
    |> validate_required([])
  end
end
