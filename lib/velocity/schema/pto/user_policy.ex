defmodule Velocity.Schema.Pto.UserPolicy do
  @moduledoc """
    User policies
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Pto.AccrualPolicy
  alias Velocity.Schema.User

  @derive {Jason.Encoder, only: [:id, :user_id, :accrual_policy_id]}

  schema "user_policies" do
    belongs_to :accrual_policy, AccrualPolicy
    belongs_to :user, User
    field :end_date, :date

    timestamps()
  end

  def build(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :end_date
    ])
    |> put_assoc(:accrual_policy, Map.get(attrs, :accrual_policy), required: true)
    |> put_assoc(:user, Map.get(attrs, :user), required: true)
  end
end
