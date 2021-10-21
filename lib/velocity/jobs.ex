defmodule Velocity.Jobs do
  @moduledoc """
  Jobs that will run on an interval
  """
  alias Timex.Interval
  alias Velocity.Contexts.Employments
  alias Velocity.Contexts.Pto.Transactions
  alias Velocity.Repo
  alias Velocity.Schema.Employment
  alias Velocity.Schema.Pto.Ledger
  alias Velocity.Schema.Pto.PtoRequestDay
  alias Velocity.Schema.Pto.UserPolicy

  import Ecto.Query

  require Logger

  @batch_size 100
  @pto_batch_size 5

  @doc """
  The nightly accrual runs on a schedule each night and adds a new credit to employee's ledgers increasing the PTO balance and carryover balance.
  """
  def nightly_accrual(opts \\ []) do
    start_date = Keyword.get(opts, :start_date, NaiveDateTime.utc_now())
    end_date = Keyword.get(opts, :end_date, NaiveDateTime.utc_now())

    [from: start_date, until: end_date]
    |> Interval.new()
    |> Interval.with_step(days: 1)
    |> Enum.map(fn naive_datetime ->
      process_batch(0, naive_datetime)
    end)
  end

  def backfill_pto do
    process_backfill_batch(0, false)
  end

  def backfill_pto_from(employment_id) do
    Logger.info("backfill employments after employment id #{employment_id}")
    process_backfill_batch(employment_id, false)
  end

  def backfill_pto_for(employment_id) do
    Logger.info("backfill employments for employment id #{employment_id}")
    process_backfill_batch(employment_id, true)
  end

  # credo:disable-for-lines:100
  defp process_backfill_batch(id, only_one) do
    Logger.info("starting backfill batch with id > #{id} and only_one = #{only_one}")

    batch = Repo.all(build_batch_query(id, only_one))
    # batch |> IO.inspect(label: "batch")

    {last_id, number_of_records} =
      Enum.reduce(batch, {id, 0}, fn employment, {_, number_of_records} ->
        Logger.info("starting employment: #{employment.id}")

        # first actually delete any dups (by unique_hash) with preference
        # to those marked as deleted
        by_row_number =
          from(l in Ledger,
            select: %{
              id: l.id,
              row_number: row_number() |> over(partition_by: l.unique_hash, order_by: l.deleted)
            },
            where: l.employment_id == ^employment.id
          )

        dups =
          from(lr in subquery(by_row_number),
            select: %{id: lr.id},
            where: lr.row_number > ^1
          )

        from(l in Ledger, select: l.id, join: d in subquery(dups), on: l.id == d.id)
        |> Repo.delete_all()

        # now mark any remaining entries as deleted
        from(l in Ledger, where: l.employment_id == ^employment.id)
        |> Repo.update_all(set: [deleted: true])

        user_policies =
          Repo.all(
            from(up in UserPolicy,
              where: up.user_id == ^employment.employee.user.id,
              preload: :accrual_policy
            )
          )

        Enum.map(user_policies, fn user_policy ->
          employment_end_date =
            if employment.end_date != nil do
              employment.end_date
            else
              Date.utc_today()
            end

          accruals = Transactions.accruals(employment.effective_date, employment_end_date)
          # accruals |> IO.inspect(label: "accruals")

          pto_requests =
            Repo.all(
              from(prd in PtoRequestDay,
                join: pr in assoc(prd, :pto_request),
                # NOTE: removing check for decision at the request
                # of the pega folks
                # pr.decision == ^"approve" and
                where:
                  prd.accrual_policy_id == ^user_policy.accrual_policy_id and
                    pr.employment_id == ^employment.id and
                    (pr.resolved_status == ^"Resolved-Completed" or
                       pr.resolved_status == ^"Resolved-Complete" or
                       pr.resolved_status == ^"Pending-StartDate")
              )
            )

          # pto_requests |> IO.inspect(label: "pto_requests")

          # because time blocks are ["afternoon", "evening"] assume each block is 4 hours
          taken_events =
            pto_requests
            |> Enum.map(&%{date: &1.day, slot: &1.slot, amount: -0.5, event_type: :taken})
            |> Enum.group_by(& &1.date)
            |> Enum.map(fn {date, events_for_date} ->
              %{
                date: date,
                event_type: :taken,
                amount: Enum.reduce(events_for_date, 0.0, fn e, total -> total + e.amount end)
              }
            end)

          # taken_events |> IO.inspect(label: "taken_events", limit: :infinity)

          ordered_events = Transactions.order_events(accruals ++ taken_events)
          # ordered_events |> IO.inspect(label: "ordered_events", limit: :infinity)

          # we want log but otherwise ignore any errors specific to
          # this employment ledger processing
          try do
            Repo.transaction(
              fn ->
                Transactions.process_events(ordered_events, %{
                  accrual_policy: user_policy.accrual_policy,
                  policy_assignment: user_policy,
                  employment: employment,
                  user: employment.employee.user
                })
              end,
              timeout: 1000 * 60 * 120
            )
          rescue
            e ->
              Logger.error(
                "ledger backfill failed for employment #{employment.id}: #{inspect(e)} #{
                  Exception.format(:error, e, __STACKTRACE__)
                }"
              )
          catch
            e ->
              Logger.error(
                "ledger backfill failed for employment #{employment.id}: #{inspect(e)} #{
                  Exception.format(:error, e, __STACKTRACE__)
                }"
              )
          end
        end)

        {employment.id, number_of_records + 1}
      end)

    if number_of_records == @pto_batch_size do
      process_backfill_batch(last_id, only_one)
    else
      Logger.info("backfill complete. last_id: #{last_id}")
    end
  end

  defp build_batch_query(id, true) do
    from(e in Employment,
      join: ee in assoc(e, :employee),
      join: u in assoc(ee, :user),
      where: e.id == ^id and e.effective_date < ^Date.utc_today(),
      preload: [employee: :user]
    )
  end

  defp build_batch_query(id, _only_one) do
    from(e in Employment,
      join: ee in assoc(e, :employee),
      join: u in assoc(ee, :user),
      where: e.id > ^id and e.effective_date < ^Date.utc_today(),
      order_by: [asc: :id],
      limit: @pto_batch_size,
      preload: [employee: :user]
    )
  end

  defp build_query(id) do
    from(up in UserPolicy,
      where: up.id > ^id,
      order_by: [asc: :id],
      limit: @batch_size,
      preload: [:user, :accrual_policy]
    )
  end

  defp process_batch(id, naive_datetime) do
    Logger.info("starting batch with id > #{id} for #{naive_datetime}")
    batch = Repo.all(build_query(id))

    {last_id, number_of_records} =
      Enum.reduce(batch, {id, 0}, fn user_policy, {_, number_of_records} ->
        try do
          employment = Employments.get_for_user(user_policy.user.id)

          if is_nil(employment) || is_nil(employment.effective_date) do
            Logger.warn(
              "no employment or employment effective date found for #{user_policy.user.id}"
            )
          else
            case Transactions.nightly_accrual(
                   user_policy.user,
                   employment,
                   user_policy.accrual_policy,
                   naive_datetime
                 ) do
              {:ok, ledger} ->
                Logger.info(
                  "nightly accrual succeeded for user: #{user_policy.user.id}. policy: #{
                    user_policy.accrual_policy.id
                  } response: #{inspect(ledger)}"
                )

              error ->
                Logger.error(
                  "nightly accrual error for user: #{user_policy.user.id}. policy: #{
                    user_policy.accrual_policy.id
                  } response: #{inspect(error)}"
                )
            end
          end
        rescue
          e ->
            Logger.error(
              "likely multiple employments for user #{user_policy.user.id}: #{inspect(e)} #{
                Exception.format(:error, e, __STACKTRACE__)
              }"
            )
        catch
          e ->
            Logger.error(
              "likely multiple employments for user #{user_policy.user.id}: #{inspect(e)} #{
                Exception.format(:error, e, __STACKTRACE__)
              }"
            )
        end

        {user_policy.id, number_of_records + 1}
      end)

    if number_of_records == @batch_size do
      process_batch(last_id, naive_datetime)
    else
      Logger.info("done. last_id: #{last_id}")
    end
  end
end
