defmodule Velocity.Schema.Pto.Ledger do
  @moduledoc """
    A ledger entry represents a debit or credit to the PTO ledger
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Employment
  alias Velocity.Schema.Pto.AccrualPolicy
  alias Velocity.Schema.Pto.Level
  alias Velocity.Schema.User
  alias Velocity.Utils.Changesets, as: Utils

  @fields [
    :event_date,
    :event_type,
    :regular_balance,
    :regular_transaction,
    :carryover_balance,
    :carryover_transaction,
    :external_case_id,
    :user_id,
    :accrual_policy_id,
    :level_id,
    :employment_id,
    :unique_hash,
    :notes
  ]

  @required_fields [
    :event_date,
    :event_type,
    :regular_balance,
    :regular_transaction,
    :carryover_balance,
    :carryover_transaction,
    :unique_hash
  ]

  @derive {Jason.Encoder, only: @fields ++ [:id]}

  @event_types [
    "policy_assignment",
    "initial_accrual",
    "accrual",
    "taken",
    "withdrawn",
    "carryover",
    "carryover_clearout",
    "manual_adjustment",
    "max_exceeded"
  ]

  schema "ledgers" do
    field :carryover_balance, :float
    field :carryover_transaction, :float
    field :event_date, :date
    field :event_type, :string
    field :external_case_id, :string
    field :regular_balance, :float
    field :regular_transaction, :float
    field :unique_hash, :string
    field :notes, :string
    belongs_to :user, User
    belongs_to :employment, Employment
    belongs_to :accrual_policy, AccrualPolicy
    belongs_to :level, Level

    timestamps()
    field :deleted, :boolean
  end

  def build(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(ledger, attrs) do
    attrs_to_hash =
      attrs
      # user_id needs to be hashed either from a nested "user" or directly from "user_id"
      |> ensure_key_from_assoc(:user_id, :user)
      # accrual_policy_id needs to be hashed either from a nested "accrual_policy" or directly from "accrual_policy_id"
      |> ensure_key_from_assoc(:accrual_policy_id, :accrual_policy)
      # level_id needs to be hashed either from a nested "level" or directly from "level_id"
      # NOTE: level is optional
      # |> ensure_key_from_assoc(:level_id, :level)
      |> ensure_key_from_assoc(:employment_id, :employment)
      |> Map.take([
        :event_date,
        :event_type,
        :regular_transaction,
        :carryover_transaction,
        :user_id,
        :accrual_policy_id,
        :level_id,
        :employment_id
      ])
      |> Map.update!(:event_date, fn event_date ->
        "#{event_date.year()}-#{event_date.month()}-#{event_date.day()}"
      end)
      |> Map.update!(:event_type, fn event_type ->
        if event_type == "initial_accraul" do
          "accrual"
        end
      end)

    hash = :crypto.hash(:md5, Jason.encode!(attrs_to_hash)) |> Base.encode16()
    updated_attrs = Map.put(attrs, :unique_hash, hash)

    ledger
    |> cast(updated_attrs, @fields)
    |> validate_required(@required_fields)
    |> Utils.maybe_put_assoc(:user, attrs)
    |> Utils.maybe_put_assoc(:accrual_policy, attrs)
    |> Utils.maybe_put_assoc(:level, attrs)
    |> Utils.maybe_put_assoc(:employment, attrs)
    |> validate_inclusion(:event_type, @event_types,
      message: "event type is invalid. valid event types are #{inspect(@event_types)}"
    )
  end

  defp ensure_key_from_assoc(map, key, assoc) do
    if Map.get(map, key) do
      map
    else
      found_key = map |> Map.get(assoc) |> Map.get(:id)

      if found_key do
        Map.put(map, key, found_key)
      else
        raise "#{key} is required"
      end
    end
  end
end
