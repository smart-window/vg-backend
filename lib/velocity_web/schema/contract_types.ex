defmodule VelocityWeb.Schema.ContractTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo

  @desc "contract"
  object :contract do
    field :id, :id
    field :uuid, :string
    field :payroll_13th_month, :string
    field :payroll_14th_month, :string
    field :termination_date, :date
    field :termination_reason, :string
    field :termination_sub_reason, :string

    field(:client, :client) do
      resolve(fn client, _args, _info ->
        client = Ecto.assoc(client, :client) |> Repo.one()
        {:ok, client}
      end)
    end
  end

  @desc "client contract report item"
  object :client_contract_report_item do
    field :id, :id
    field :client_name, :string
    field :region_name, :string
    field :operating_countries, :string
    field :total_employees, :integer
    field :active_employees, :integer
  end

  object :paginated_client_contracts_report do
    field :row_count, :integer
    field :client_contract_report_items, list_of(:client_contract_report_item)
  end
end
