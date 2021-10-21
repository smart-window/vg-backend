defmodule VelocityWeb.Schema.TeamTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  @desc "team"
  object :team do
    field :id, :id
    field :name, :string
    field :parent_id, :id
  end
end
