defmodule Velocity.Schema.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Tag

  schema "tags" do
    field :name, :string

    belongs_to :parent, Tag

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
