defmodule Velocity.Contexts.Pto.Carryover do
  @moduledoc """
  Carryover is a PTO event which will roll over balance into the subsequent period
  """

  alias Velocity.Contexts.Pto.Ledgers

  def calculate(_, nil, _, _) do
    nil
  end

  def calculate(%{carryover_limit_type: "unlimited"}, _, _, _) do
    nil
  end

  def calculate(
        %{carryover_limit: carryover_limit, carryover_day: carryover_day},
        last_ledger,
        event_date,
        employee_start_date
      ) do
    if should_perform_carryover?(
         carryover_day,
         event_date,
         employee_start_date,
         last_ledger
       ) &&
         (last_ledger.event_type != "carryover" ||
            last_ledger.event_type != "carryover_clearout") do
      {:ok, after_clearout_ledger} = carryover_clearout(last_ledger, event_date)
      {:ok, ledger} = carryover(carryover_limit, last_ledger, after_clearout_ledger, event_date)
      ledger
    else
      nil
    end
  end

  def should_perform_carryover?(_, _, _, nil) do
    false
  end

  def should_perform_carryover?("anniversary", event_date, employee_start_date, ledger) do
    Date.day_of_year(employee_start_date) == Date.day_of_year(event_date) &&
      ledger.regular_balance > 0
  end

  def should_perform_carryover?("hire", event_date, employee_start_date, ledger) do
    Date.day_of_year(employee_start_date) == Date.day_of_year(event_date) &&
      ledger.regular_balance > 0
  end

  def should_perform_carryover?("first_of_year", event_date, _, ledger) do
    Date.day_of_year(event_date) == 1 && ledger.regular_balance > 0
  end

  def should_perform_carryover?("first", event_date, _, ledger) do
    Date.day_of_year(event_date) == 1 && ledger.regular_balance > 0
  end

  def should_perform_carryover?(day, event_date, _, _) when is_binary(day) do
    String.to_integer(day) == Date.day_of_year(event_date)
  end

  defp carryover(_, _, nil, _) do
    {:ok, nil}
  end

  defp carryover(
         carryover_limit,
         %{
           regular_balance: regular_balance_before_clearout,
           carryover_balance: carryover_balance_before_clearout
         },
         last_ledger,
         event_date
       ) do
    amount_to_carry =
      if regular_balance_before_clearout + carryover_balance_before_clearout > carryover_limit do
        carryover_limit
      else
        regular_balance_before_clearout + carryover_balance_before_clearout
      end

    Ledgers.add_next_ledger(last_ledger, event_date, "carryover", nil, 0, amount_to_carry)
  end

  defp carryover_clearout(last_ledger, event_date) do
    regular_transaction = last_ledger.regular_balance * -1
    carryover_transaction = last_ledger.carryover_balance * -1

    Ledgers.add_next_ledger(
      last_ledger,
      event_date,
      "carryover_clearout",
      nil,
      regular_transaction,
      carryover_transaction
    )
  end
end
