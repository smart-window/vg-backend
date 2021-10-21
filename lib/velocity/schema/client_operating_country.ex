defmodule Velocity.Schema.ClientOperatingCountry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Client
  alias Velocity.Schema.Country

  schema "client_operating_countries" do
    field :annual_leave, :string
    field :client_on_faster_reimbursement, :boolean, default: false
    field :notes, :string
    field :notice_period_length, :string
    field :other_insurance_offered, :string
    field :private_medical_insurance, :string
    field :probationary_period_length, :string
    field :sick_leave, :string
    field :standard_additions_deadline, :string
    field :standard_allowances_offered, :string
    field :standard_bonuses_offered, :string
    belongs_to :client, Client
    belongs_to :country, Country

    timestamps()
  end

  @doc false
  def changeset(client_operating_country, attrs) do
    client_operating_country
    |> cast(attrs, [
      :client_id,
      :country_id,
      :probationary_period_length,
      :notice_period_length,
      :private_medical_insurance,
      :other_insurance_offered,
      :annual_leave,
      :sick_leave,
      :standard_additions_deadline,
      :client_on_faster_reimbursement,
      :standard_allowances_offered,
      :standard_bonuses_offered,
      :notes
    ])
    |> validate_required([
      :client_id,
      :country_id,
      :probationary_period_length,
      :notice_period_length,
      :private_medical_insurance,
      :other_insurance_offered,
      :annual_leave,
      :sick_leave,
      :standard_additions_deadline,
      :client_on_faster_reimbursement,
      :standard_allowances_offered,
      :standard_bonuses_offered,
      :notes
    ])
  end
end
