defmodule VelocityWeb.Schema.AddressTypes do
  @moduledoc false

  alias Velocity.Repo
  use Absinthe.Schema.Notation

  @desc "address"
  object :address do
    field :id, :id
    field :line_1, :string
    field :line_2, :string
    field :line_3, :string
    field :city, :string
    field :postal_code, :string
    field :county_district, :string
    field :state_province, :string
    field :state_province_is_alpha_2_code, :string

    field(:country, :country) do
      resolve(fn address, _args, _info ->
        country = Ecto.assoc(address, :country) |> Repo.one()
        {:ok, country}
      end)
    end

    field :timezone, :string
  end
end
