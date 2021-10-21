defmodule Velocity.Schema.InternalEmployee do
  @moduledoc "
    schema for internal employee
    represents users that can be employed and are internal
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Employee

  schema "internal_employees" do
    field :job_title, :string
    belongs_to :employee, Employee

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :employee_id,
      :job_title
    ])
    |> validate_required([
      :employee_id
    ])
  end
end
