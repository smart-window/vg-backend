defmodule Velocity.Schema.ExternalEmployee do
  @moduledoc "
    schema for external employee
    represents external users that can be employed external)
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Employee

  schema "external_employees" do
    belongs_to :employee, Employee

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :employee_id
    ])
    |> validate_required([
      :employee_id
    ])
  end
end
