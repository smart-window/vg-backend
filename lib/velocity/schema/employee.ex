defmodule Velocity.Schema.Employee do
  @moduledoc "
    schema for employee
    represents users that can be employed (internal or external)
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Employment
  alias Velocity.Schema.User

  schema "employees" do
    field :pega_ak, :string
    field :pega_pk, :string
    belongs_to :user, User
    has_many :employments, Employment

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :user_id,
      :pega_ak,
      :pega_pk
    ])
    |> validate_required([
      :user_id
    ])
  end
end
