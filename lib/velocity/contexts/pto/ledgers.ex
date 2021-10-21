defmodule Velocity.Contexts.Pto.Ledgers do
  @moduledoc """
  Ledgers represent all debits and credits to an employee's PTO.
  Ledger entries should be immutable and PTO totals should be able to be calculated at any time by "restreaming" the entries.
  """

  require Logger

  alias Velocity.Repo
  alias Velocity.Schema.Pto.AccrualPolicy
  alias Velocity.Schema.Pto.Ledger
  alias Velocity.Schema.User
  alias Velocity.Utils.Math

  import Ecto.Query

  def export_all_to_csv do
    ledgers =
      Repo.all(
        from(l in Ledger, where: l.deleted == false, join: u in assoc(l, :user), preload: :user)
      )

    tmp_dir = System.tmp_dir!()

    [
      [
        "full_name",
        "email",
        "okta_user_uid",
        "id",
        "event_date",
        "event_type",
        "regular_balance",
        "regular_transaction",
        "carryover_balance",
        "carryover_transaction",
        "accrual_policy_id",
        "level_id",
        "user_id"
      ]
    ]
    |> Stream.concat(
      ledgers
      |> Stream.map(
        &[
          &1.user.full_name,
          &1.user.email,
          &1.user.okta_user_uid,
          &1.id,
          &1.event_date,
          &1.event_type,
          &1.regular_balance,
          &1.regular_transaction,
          &1.carryover_balance,
          &1.carryover_transaction,
          &1.accrual_policy_id,
          &1.level_id,
          &1.user_id
        ]
      )
    )
    |> CSV.encode()
    |> Enum.into(File.stream!(Path.join(tmp_dir, "#{Ecto.UUID.generate()}.csv")))
  end

  def is_first_accrual?(employment, accrual_policy) do
    not Repo.exists?(
      from l in Ledger,
        where:
          l.employment_id == ^employment.id and l.accrual_policy_id == ^accrual_policy.id and
            l.event_type == "initial_accrual" and
            l.deleted == false,
        limit: 1
    )
  end

  def days_taken(
        user = %User{},
        accrual_policy = %AccrualPolicy{}
      ) do
    query =
      from(l in Ledger,
        where:
          l.user_id == ^user.id and l.accrual_policy_id == ^accrual_policy.id and
            (l.event_type == "taken" or l.event_type == "withdrawn") and l.deleted == false
      )

    regular = Repo.aggregate(query, :sum, :regular_transaction) || 0
    carryover = Repo.aggregate(query, :sum, :carryover_transaction) || 0
    regular + carryover
  end

  def first_ledger_entry(
        user = %User{},
        accrual_policy = %AccrualPolicy{}
      ) do
    Repo.one(
      from l in Ledger,
        where:
          l.user_id == ^user.id and l.accrual_policy_id == ^accrual_policy.id and
            l.deleted == false,
        order_by: [asc: l.event_date, asc: l.id],
        limit: 1
    )
  end

  def last_ledger_entry(
        user = %User{},
        accrual_policy = %AccrualPolicy{},
        _override_ledger_id \\ nil
      ) do
    Repo.one(
      from l in Ledger,
        where:
          l.user_id == ^user.id and l.accrual_policy_id == ^accrual_policy.id and
            l.deleted == false,
        order_by: [desc: l.id],
        limit: 1
    )
  end

  def get_ledger_entries(user = %User{}, accrual_policy = %AccrualPolicy{}) do
    Repo.all(
      from l in Ledger,
        where:
          l.user_id == ^user.id and l.accrual_policy_id == ^accrual_policy.id and
            l.deleted == false,
        order_by: [asc: l.event_date, asc: l.id]
    )
  end

  def add_next_ledger(
        _,
        _,
        _,
        _,
        regular_transaction \\ 0,
        carryover_transaction \\ 0
      )

  def add_next_ledger(
        nil,
        _event_date,
        _event_type,
        _notes,
        _regular_transaction,
        _carryover_transaction
      ) do
    Logger.error(
      "add_next_ledger called with current_ledger == nil. this might mean the user is not assigned to the accrual policy. #{
        inspect(Process.info(self(), :current_stacktrace))
      }"
    )
  end

  def add_next_ledger(
        current_ledger,
        event_date,
        event_type,
        notes,
        regular_transaction,
        carryover_transaction
      ) do
    create(%{
      user_id: current_ledger.user_id,
      accrual_policy_id: current_ledger.accrual_policy_id,
      level_id: current_ledger.level_id,
      employment_id: current_ledger.employment_id,
      event_date: event_date,
      event_type: event_type,
      notes: notes,
      carryover_balance: Math.round(current_ledger.carryover_balance + carryover_transaction),
      carryover_transaction: Math.round(carryover_transaction),
      regular_balance: Math.round(current_ledger.regular_balance + regular_transaction),
      regular_transaction: Math.round(regular_transaction)
    })
  end

  def create(params, opts \\ []) do
    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    options =
      Keyword.merge(opts,
        on_conflict: [set: [updated_at: inserted_and_updated_at]],
        conflict_target: [:deleted, :unique_hash],
        returning: true
      )

    changeset = Ledger.changeset(%Ledger{}, params)

    Repo.insert(changeset, options)
  end

  def get_by(keyword) do
    Repo.get_by(Ledger, Keyword.merge(keyword, deleted: false))
  end

  def list(user = %User{}, accrual_policy = %AccrualPolicy{}) do
    query =
      from(l in Ledger,
        where:
          l.user_id == ^user.id and l.accrual_policy_id == ^accrual_policy.id and
            l.deleted == false
      )

    last_ledger = last_ledger_entry(user, accrual_policy)

    %{ledgers: Repo.all(query), last_ledger: last_ledger, accrual_policy: accrual_policy}
  end

  def list(user_id, accrual_policy_id) do
    query =
      from(l in Ledger,
        where:
          l.user_id == ^user_id and l.accrual_policy_id == ^accrual_policy_id and
            l.deleted == false
      )

    Repo.all(query)
  end

  def delete_ledgers(user_id, accrual_policy_id) do
    query =
      from(l in Ledger,
        where: l.user_id == ^user_id and l.accrual_policy_id == ^accrual_policy_id
      )

    Repo.update_all(query, set: [deleted: true])
  end
end
