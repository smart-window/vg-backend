defmodule Velocity.Schema.Pto.PtoType do
  @moduledoc "schema for PTO types"
  use Ecto.Schema
  import Ecto.Changeset

  schema "pto_types" do
    field :name, :string
    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
