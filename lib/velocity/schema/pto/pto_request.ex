defmodule Velocity.Schema.Pto.PtoRequest do
  @moduledoc "
    schema for PTO request
    represents a PTO request for an employment
  "
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Employment
  alias Velocity.Schema.Pto.PtoRequestDay
  alias Velocity.Schema.User

  schema "pto_requests" do
    field :request_comment, :string
    field :decision, PTODecisionEnum
    field :decision_comment, :string
    field :resolved_status, :string

    belongs_to :employment, Employment
    belongs_to :decided_by_user, User
    has_many :pto_request_days, PtoRequestDay, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :employment_id,
      :decided_by_user_id,
      :request_comment,
      :decision,
      :decision_comment
    ])
    |> validate_required([
      :employment_id
    ])
  end
end
