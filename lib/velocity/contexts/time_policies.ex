defmodule Velocity.Contexts.TimePolicies do
  @moduledoc "context for time_policies"

  alias Velocity.Repo
  alias Velocity.Schema.TimePolicy

  def create(params) do
    changeset = TimePolicy.changeset(%TimePolicy{}, params)

    Repo.insert(changeset)
  end

  def get_by(keyword) do
    Repo.get_by(TimePolicy, keyword)
  end
end
