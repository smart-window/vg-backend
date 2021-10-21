defmodule Velocity.Schema.EmploymentClientManager do
  @moduledoc "
    schema for employment client manager
    represents an association between a client manager and an employment
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.ClientManager
  alias Velocity.Schema.Employment

  schema "employment_client_managers" do
    field :effective_date, :date

    belongs_to :employment, Employment
    belongs_to :client_manager, ClientManager

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :employment_id,
      :client_manager_id,
      :effective_date
    ])
    |> validate_required([
      :employment_id,
      :client_manager_id,
      :effective_date
    ])
  end
end
