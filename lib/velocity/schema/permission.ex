defmodule Velocity.Schema.Permission do
  @moduledoc "schema for permissions"
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
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
