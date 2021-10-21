defmodule Velocity.Schema.ClientOnboarding do
  @moduledoc "
    schema for client_onboarding
    represents an client_onboarding of a job by an employee under a contract
    which is manageable by client managers
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Contract
  alias Velocity.Schema.Process

  schema "client_onboardings" do
    belongs_to :contract, Contract
    belongs_to :process, Process

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :contract_id,
      :process_id
    ])
    |> validate_required([
      :contract_id,
      :process_id
    ])
  end
end
