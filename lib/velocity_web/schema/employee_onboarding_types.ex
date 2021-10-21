defmodule VelocityWeb.Schema.EmployeeOnboardingTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo
  alias Velocity.Schema.Employment
  alias Velocity.Schema.Process

  @desc "employee_onboarding"
  object :employee_onboarding do
    field :id, :id
    field :contract_id, :string
    field :employment_id, :id
    field :process_id, :id
    field :full_name, :string
    field :partner_name, :string
    field :client_name, :string
    field :region_name, :string
    field :country_name, :string
    field :percent_complete, :float
    field :anticipated_start_date, :string
    field :signature_status, :string
    field :immigration, :boolean
    field :benefits, :boolean

    field(:employment, :employment) do
      resolve(fn eo, _args, _info ->
        employment = Repo.get(Employment, eo.employment_id)
        {:ok, employment}
      end)
    end

    field(:process, :process) do
      resolve(fn eo, _args, _info ->
        process = Repo.get(Process, eo.process_id)
        {:ok, process}
      end)
    end
  end

  object :paginated_employee_onboardings do
    field :row_count, :integer
    field :employee_onboardings, list_of(:employee_onboarding)
  end
end
