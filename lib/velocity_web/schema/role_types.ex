defmodule VelocityWeb.Schema.RoleTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  @desc "role"
  object :role do
    field :id, :id
    field :slug, :string
    field :description, :string
  end
end
