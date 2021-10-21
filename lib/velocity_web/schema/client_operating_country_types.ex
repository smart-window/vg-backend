defmodule VelocityWeb.Schema.ClientOperatingCountryTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo

  @desc "client_operating_country"
  object :client_operating_country do
    field :id, :id
    field :probationary_period_length, :string
    field :notice_period_length, :string
    field :private_medical_insurance, :string
    field :other_insurance_offered, :string
    field :annual_leave, :string
    field :sick_leave, :string
    field :standard_additions_deadline, :string
    field :client_on_faster_reimbursement, :boolean
    field :standard_allowances_offered, :string
    field :standard_bonuses_offered, :string
    field :notes, :string

    field(:country, :country) do
      resolve(fn client_operating_country, _args, _info ->
        country = Ecto.assoc(client_operating_country, :country) |> Repo.one()
        {:ok, country}
      end)
    end
  end
end
