defmodule Velocity.Schema.TimeType do
  @moduledoc "schema for time_types"
  use Ecto.Schema
  import Ecto.Changeset

  schema "time_types" do
    field :slug, :string
    field :description, :string

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:slug, :description])
    |> validate_required([:slug])
  end
end
