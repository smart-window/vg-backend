defmodule Velocity.Contexts.TimeTypes do
  @moduledoc "context for time_types"

  alias Velocity.Repo
  alias Velocity.Schema.TimePolicy
  alias Velocity.Schema.TimePolicyType
  alias Velocity.Schema.TimeType

  def create(params) do
    changeset = TimeType.changeset(%TimeType{}, params)

    Repo.insert(changeset)
  end

  def add_time_type_to_time_policy(time_type = %TimeType{}, time_policy = %TimePolicy{}) do
    changeset =
      TimePolicyType.changeset(%TimePolicyType{}, %{
        time_type: time_type,
        time_policy: time_policy
      })

    Repo.insert(changeset)
  end
end
