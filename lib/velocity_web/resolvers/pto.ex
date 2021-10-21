defmodule VelocityWeb.Resolvers.Pto do
  @moduledoc """
  GQL resolver for pto
  """

  alias Velocity.Contexts.Employments
  alias Velocity.Contexts.Pto.AccrualPolicies
  alias Velocity.Contexts.Pto.Ledgers
  alias Velocity.Contexts.Pto.Transactions
  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.Contexts.Users
  alias Velocity.Repo

  require Logger

  def simulate(args, _) do
    Logger.info("simulation args: #{inspect(args)}")
    persist_data = Map.get(args, :persist)

    # simulation

    function = fn ->
      with {:ok, %{accrual_policy: accrual_policy}} <-
             AccrualPolicies.find_or_create(args.accrual_policy),
           {:ok, user} <- Users.find_or_create(args.user),
           {:ok, user_with_start_date} <-
             {:ok, Map.put(user, :start_date, args.user.start_date)},
           {:ok, employment} <-
             Employments.find_or_create_for_pto_simulation(user, args.user.start_date),
           {:ok, assignment} <-
             UserPolicies.assign_user_policy(
               user_with_start_date,
               args.user.start_date,
               accrual_policy,
               args.start_date
             ),
           accrual_events when is_list(accrual_events) <-
             Transactions.accruals(args.start_date, args.end_date),
           taken_events when is_list(taken_events) <-
             Transactions.taken_events(Map.get(args, :taken_events, [])),
           withdrawn_events when is_list(withdrawn_events) <-
             Transactions.withdrawn_events(Map.get(args, :withdrawn_events, [])),
           manual_events when is_list(manual_events) <-
             Transactions.manual_events(Map.get(args, :manual_events, [])),
           ordered_events when is_list(ordered_events) <-
             Transactions.order_events(
               accrual_events ++
                 taken_events ++
                 withdrawn_events ++
                 manual_events
             ),
           {:ok, _ledger} <-
             Transactions.process_events(ordered_events, %{
               accrual_policy: accrual_policy,
               employment: employment,
               policy_assignment: assignment,
               user: user_with_start_date,
               ordered_events: ordered_events
             }) do
        if persist_data do
          {:ok, Ledgers.get_ledger_entries(user, accrual_policy)}
        else
          Repo.rollback({:ok, Ledgers.get_ledger_entries(user, accrual_policy)})
        end
      else
        any ->
          if persist_data do
            {:error, any}
          else
            Repo.rollback(any)
          end
      end
    end

    if persist_data do
      without_rollback(function)
    else
      with_rollback(function)
    end
  end

  defp with_rollback(function) do
    case Repo.transaction(function,
           timeout: 1000 * 60
         ) do
      {:error, {:ok, ledgers}} ->
        {:ok, ledgers}

      error ->
        Logger.error("simulation error: #{inspect(error)}")
        {:error, %{message: inspect(error)}}
    end
  end

  defp without_rollback(function) do
    case function.() do
      {:ok, ledgers} ->
        {:ok, ledgers}

      {:error, error} ->
        Logger.error("simulation error: #{inspect(error)}")
        {:error, error}

      error ->
        Logger.error("simulation error: #{inspect(error)}")
        {:error, %{message: inspect(error)}}
    end
  end
end
