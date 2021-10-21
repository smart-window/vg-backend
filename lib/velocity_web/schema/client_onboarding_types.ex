defmodule VelocityWeb.Schema.ClientOnboardingTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo
  alias Velocity.Schema.Contract
  alias Velocity.Schema.Process

  @desc "client_onboarding"
  object :client_onboarding do
    field :id, :id
    field :contract_id, :id
    field :process_id, :id
    field :client_id, :id
    field :full_name, :string
    field :partner_id, :id
    field :partner_name, :string
    field :region_name, :string
    field :country_id, :id
    field :country_short_name, :string
    field :country_name, :string
    field :percent_complete, :float
    field :employees, :integer

    field(:contract, :contract) do
      resolve(fn co, _args, _info ->
        contract = Repo.get(Contract, co.contract_id)
        {:ok, contract}
      end)
    end

    field(:process, :process) do
      resolve(fn co, _args, _info ->
        process = Repo.get(Process, co.process_id)
        {:ok, process}
      end)
    end
  end

  object :paginated_client_onboardings do
    field :row_count, :integer
    field :client_onboardings, list_of(:client_onboarding)
  end
end
