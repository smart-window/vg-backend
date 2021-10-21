defmodule Velocity.Schema.Job do
  @moduledoc "
    schema for job
    represents a client job that is employable.
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Client

  schema "jobs" do
    field :title, :string
    field :probationary_period_length, :float
    field :probationary_period_term, ProbationaryPeriodTermEnum
    belongs_to :client, Client

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :client_id,
      :title,
      :probationary_period_length,
      :probationary_period_term
    ])
    |> validate_required([
      :client_id,
      :title
    ])
  end
end
