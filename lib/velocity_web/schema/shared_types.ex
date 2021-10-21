defmodule VelocityWeb.Schema.SharedTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  input_object :filter_by do
    field :name, :string
    field :value, :string
  end
end
