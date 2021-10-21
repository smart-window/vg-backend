defmodule Velocity.Contexts.Pto.Transactions do
  @moduledoc false

  alias Timex.Interval
  alias Velocity.Contexts.Employments
  alias Velocity.Contexts.Pto.Carryover
  alias Velocity.Contexts.Pto.Ledgers
  alias Velocity.Contexts.Pto.Levels
  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.Pto.Ledger
  alias Velocity.Utils.Dates, as: Utils

  require Logger

  @doc """
  The nightly accrual adds a new credit to employee's ledgers increasing the PTO balance and carryover balance.

  The User (employee) will be found based on the 'okta_user_uid'.
  The Policy will be found based on the 'pega_policy_id'.
  """
  def nightly_accrual(
        _user,
        _employment,
        _accrual_policy,
        _event_date \\ Date.utc_today(),
        _last_ledger_override \\ nil
      )

  def nightly_accrual(
        user,
        employment,
        accrual_policy,
        event_date,
        last_ledger_override
      )
      when not is_nil(employment) do
    # employment |> IO.inspect(label: "nightly accrual employment")
    if UserPolicies.get_by(user_id: user.id, accrual_policy_id: accrual_policy.id) do
      level = Levels.determine_level(employment.effective_date, accrual_policy, event_date)
      # level |> IO.inspect(label: "nightly accrual level")
      current_ledger = Ledgers.last_ledger_entry(user, accrual_policy, last_ledger_override)

      if level do
        is_first_accrual = is_first_accrual?(current_ledger, employment, accrual_policy)

        ledger_after_carryover =
          Carryover.calculate(
            %{
              carryover_day: accrual_policy.carryover_day,
              carryover_limit_type: get_carryover_limit_type(level.carryover_limit_type),
              carryover_limit: level.carryover_limit
            },
            current_ledger,
            event_date,
            employment.effective_date
          )

        last_ledger =
          ledger_after_carryover || current_ledger ||
            %Ledger{
              user_id: user.id,
              accrual_policy_id: accrual_policy.id,
              employment_id: employment.id,
              level_id: level.id,
              event_type: "placeholder",
              event_date: Date.utc_today(),
              regular_balance: 0,
              regular_transaction: 0,
              carryover_balance: 0,
              carryover_transaction: 0
            }

        if should_accrue?(
             event_date,
             Map.put(level, :carryover_day, accrual_policy.carryover_day),
             employment.effective_date
           ) do
          amount_to_add_regular_balance =
            if is_first_accrual && accrual_policy.first_accrual_policy == "prorate" do
              prorate_multiplier(event_date, level) * level.accrual_amount
            else
              level.accrual_amount
            end

          event_type = if is_first_accrual, do: "initial_accrual", else: "accrual"

          response =
            Ledgers.add_next_ledger(
              last_ledger,
              event_date,
              event_type,
              nil,
              amount_to_add_regular_balance,
              0
            )

          check_max(level.max_days, response)
        else
          {:ok, %{message: "nothing to accrue"}}
        end
      else
        # assume this is okay (policy with no level)
        {:ok, %{message: "nothing to accrue"}}
      end
    else
      {:error,
       "user policy assignment not found for user: #{user.okta_user_uid} and accrual_policy: #{
         accrual_policy.pega_policy_id
       }"}
    end
  end

  def nightly_accrual(
        user,
        nil,
        accrual_policy,
        event_date,
        last_ledger_override
      ) do
    {:ok, %{status: 200, body: body}} = pega_client().hire_date_by_okta_uid(user.okta_user_uid)

    employee_start_date =
      body
      |> Map.get("pxResults")
      |> List.first()
      |> Map.fetch!("EmploymentStatusEffectiveDate")
      |> String.replace("-", "")

    Users.update!(user, %{start_date: Utils.parse_pega_date!(employee_start_date)})

    nightly_accrual(
      user,
      %{effective_date: employee_start_date},
      accrual_policy,
      event_date,
      last_ledger_override
    )
  end

  def accrue_between_dates(
        user_policy = %{user: user, accrual_policy: accrual_policy},
        start_date,
        end_date
      ) do
    Repo.transaction(
      fn ->
        accrual_events = accruals(start_date, end_date)
        employment = Employments.get_for_user(user.id)

        {:ok, _ledger} =
          process_events(accrual_events, %{
            accrual_policy: accrual_policy,
            employment: employment,
            policy_assignment: user_policy,
            user: user,
            ordered_events: accrual_events
          })
      end,
      timeout: 1000 * 60
    )
  end

  def check_max(max, response = {:ok, ledger}) do
    if ledger.regular_balance + ledger.carryover_balance > max do
      amount = max + -(ledger.regular_balance + ledger.carryover_balance)
      Ledgers.add_next_ledger(ledger, ledger.event_date, "max_exceeded", nil, amount, 0)
    else
      response
    end
  end

  def check_max(_max, last_ledger_response) do
    last_ledger_response
  end

  def taken(_, _, _, event_date \\ DateTime.utc_now(), last_ledger_override \\ nil)

  def taken(%{amount: amount}, _, _, _, _) when amount >= 0,
    do: {:error, "pto taken amount must be a negative number"}

  def taken(
        %{amount: amount, notes: notes, employment: employment},
        user,
        accrual_policy,
        event_date,
        last_ledger_override
      )
      when amount < 0 do
    if UserPolicies.get_by(user_id: user.id, accrual_policy_id: accrual_policy.id) do
      level = Levels.determine_level(employment.effective_date, accrual_policy, event_date)

      level_id = if level, do: level.id, else: nil

      current_ledger =
        Ledgers.last_ledger_entry(
          user,
          accrual_policy,
          last_ledger_override
        ) ||
          %Ledger{
            user_id: user.id,
            accrual_policy_id: accrual_policy.id,
            employment_id: employment.id,
            level_id: level_id,
            event_type: "placeholder",
            event_date: Date.utc_today(),
            regular_balance: 0,
            regular_transaction: 0,
            carryover_balance: 0,
            carryover_transaction: 0
          }

      carryover_balance = current_ledger.carryover_balance
      regular_balance = current_ledger.regular_balance
      absolute_amount = abs(amount)

      %{
        carryover_transaction: carryover_transaction,
        regular_transaction: regular_transaction
      } =
        cond do
          carryover_balance > 0 and absolute_amount < carryover_balance ->
            %{
              carryover_transaction: amount,
              regular_transaction: 0
            }

          carryover_balance <= 0 and absolute_amount > regular_balance ->
            %{
              carryover_transaction: 0,
              regular_transaction: amount
            }

          # take the entire carryover
          true ->
            carryover_transaction = -carryover_balance
            remainding_to_take = amount + carryover_balance
            regular_transaction = remainding_to_take

            %{
              carryover_transaction: carryover_transaction,
              regular_transaction: regular_transaction
            }
        end

      Ledgers.add_next_ledger(
        current_ledger,
        event_date,
        "taken",
        notes,
        regular_transaction,
        carryover_transaction
      )
    else
      {:error,
       "user policy assignment not found for user: #{user.okta_user_uid} and accrual_policy: #{
         accrual_policy.pega_policy_id
       }"}
    end
  end

  def withdrawn(
        regular_transaction,
        carryover_transaction,
        notes,
        user,
        accrual_policy,
        event_date \\ DateTime.utc_now(),
        last_ledger_override \\ nil
      )
      when regular_transaction >= 0 and carryover_transaction >= 0 do
    current_ledger = Ledgers.last_ledger_entry(user, accrual_policy, last_ledger_override)

    Ledgers.add_next_ledger(
      current_ledger,
      event_date,
      "withdrawn",
      notes,
      regular_transaction,
      carryover_transaction
    )
  end

  def manual_adjustment(
        amount,
        user,
        accrual_policy,
        notes,
        event_date \\ DateTime.utc_now(),
        last_ledger_override \\ nil
      ) do
    current_ledger = Ledgers.last_ledger_entry(user, accrual_policy, last_ledger_override)

    Ledgers.add_next_ledger(
      current_ledger,
      event_date,
      "manual_adjustment",
      notes,
      amount,
      0
    )
  end

  def is_first_accrual?(current_ledger, employment, accrual_policy) do
    if current_ledger && current_ledger.event_type == "policy_assignment" do
      true
    else
      Ledgers.is_first_accrual?(employment, accrual_policy)
    end
  end

  def should_accrue?(
        event_date,
        %{
          accrual_period: "days",
          accrual_frequency: accrual_frequency,
          effective_date: effective_date
        },
        _
      )
      when not is_nil(effective_date) do
    rem(
      Timex.diff(event_date, effective_date, :days) + 1,
      floor(accrual_frequency)
    ) == 0 && Timex.compare(effective_date, event_date) <= 0
  end

  def should_accrue?(
        event_date,
        %{
          accrual_period: "weeks",
          accrual_frequency: accrual_frequency,
          accrual_calculation_week_day: accrual_calculation_week_day,
          effective_date: effective_date
        },
        _
      )
      when not is_nil(effective_date) do
    rem(
      Timex.diff(event_date, effective_date, :weeks),
      floor(accrual_frequency)
    ) == 0 && Timex.weekday(event_date) == accrual_calculation_week_day &&
      Timex.compare(effective_date, event_date) <= 0
  end

  def should_accrue?(
        event_date,
        %{
          accrual_period: "months",
          accrual_calculation_month_day: "1,15",
          effective_date: effective_date
        },
        _
      )
      when not is_nil(effective_date) do
    (event_date.day == 1 || event_date.day == 15) &&
      Timex.compare(effective_date, event_date) <= 0
  end

  def should_accrue?(
        event_date,
        %{
          accrual_period: "months",
          accrual_calculation_month_day: "15,last",
          effective_date: effective_date
        },
        _
      )
      when not is_nil(effective_date) do
    (event_date.day == 15 || Timex.end_of_month(event_date).day == event_date.day) &&
      Timex.compare(effective_date, event_date) <= 0
  end

  def should_accrue?(
        event_date,
        %{
          accrual_period: "months",
          accrual_calculation_month_day: "last",
          effective_date: effective_date
        },
        _
      )
      when not is_nil(effective_date) do
    Timex.end_of_month(event_date).day == event_date.day &&
      Timex.compare(effective_date, event_date) <= 0
  end

  def should_accrue?(
        event_date,
        %{
          accrual_period: "months",
          accrual_calculation_month_day: accrual_calculation_month_day,
          effective_date: effective_date
        },
        _
      ) do
    if Timex.compare(effective_date, event_date) <= 0 do
      days_to_accrue =
        accrual_calculation_month_day
        |> String.split(",")
        |> Enum.map(fn potential_integer ->
          {integer, _} = Integer.parse(potential_integer)
          integer
        end)

      if event_date.day in days_to_accrue do
        true
      else
        false
      end
    else
      false
    end
  end

  def should_accrue?(
        event_date,
        %{
          accrual_period: "years",
          accrual_calculation_year_month: "hire",
          effective_date: effective_date
        },
        hire_date
      )
      when not is_nil(effective_date) do
    Timex.diff(event_date, hire_date, :years) > 0 && hire_date.month == event_date.month &&
      hire_date.day == event_date.day && Timex.compare(effective_date, event_date) <= 0
  end

  def should_accrue?(
        event_date,
        %{
          accrual_period: "years",
          accrual_calculation_year_day: accrual_calculation_year_day,
          accrual_calculation_year_month: accrual_calculation_year_month,
          effective_date: effective_date
        },
        _
      )
      when not is_nil(effective_date) do
    String.to_integer(accrual_calculation_year_month) == event_date.month &&
      accrual_calculation_year_day == event_date.day &&
      Timex.compare(effective_date, event_date) <= 0
  end

  def prorate_multiplier(
        _event_date,
        %{accrual_period: "days"}
      ) do
    1
  end

  def prorate_multiplier(
        event_date,
        %{
          accrual_period: "weeks",
          accrual_frequency: accrual_frequency,
          effective_date: effective_date
        }
      ) do
    number_of_days = Timex.diff(event_date, effective_date, :days)

    days_in_frequency =
      accrual_frequency
      |> Timex.Duration.from_weeks()
      |> Timex.Duration.to_days()

    number_of_days / days_in_frequency
  end

  def prorate_multiplier(
        event_date,
        %{accrual_period: "months", effective_date: effective_date}
      )
      when not is_nil(effective_date) do
    number_of_days = Timex.diff(event_date, effective_date, :days)

    number_of_days / Timex.days_in_month(event_date)
  end

  def prorate_multiplier(
        event_date,
        %{accrual_period: "years", effective_date: effective_date}
      ) do
    days_worked =
      [from: effective_date, until: event_date]
      |> Interval.new()
      |> Interval.duration(:days)

    days_in_year = event_date |> Timex.end_of_year() |> Timex.day()

    days_worked / days_in_year
  end

  def accruals(start_date, end_date) do
    [from: start_date, left_open: true, right_open: true, until: end_date]
    |> Interval.new()
    |> Interval.with_step(days: 1)
    |> Enum.map(&%{event_type: :accrual, date: NaiveDateTime.to_date(&1)})
  end

  def taken_events(events) do
    Enum.map(events, &Map.put(&1, :event_type, :taken))
  end

  def manual_events(events) do
    Enum.map(events, &Map.put(&1, :event_type, :manual))
  end

  def withdrawn_events(events) do
    Enum.map(events, &Map.put(&1, :event_type, :withdrawn))
  end

  def order_events(events) do
    Enum.sort_by(events, & &1.date, Date)
    #    Enum.sort(events, fn lhs, rhs ->
    #      result = Date.compare(lhs.date, rhs.date)
    #      case result do
    #        :lt -> true
    #        :gt -> false
    #        :eq -> true
    # Enum.find_index(PTOSlotEnum.__enum_map__(), fn x -> x == lhs.slot end) <= Enum.find_index(PTOSlotEnum.__enum_map__(), fn x -> x == rhs.slot end)
    #      end
    #     end)
  end

  def process_events([], _args) do
    {:ok, "no events left"}
  end

  def process_events(ordered_events, args) do
    [event | tail] = ordered_events

    case process_event(event, args) do
      {:ok, ledger = %Ledger{}} ->
        process_events(tail, Map.put(args, :override_ledger, ledger))

      {:ok, _} ->
        process_events(tail, args)

      {:error, error} ->
        {:error, error}
    end
  end

  defp process_event(
         event = %{event_type: :accrual},
         args = %{
           accrual_policy: accrual_policy,
           user: user
         }
       ) do
    # event |> IO.inspect(label: "processing accrual event")
    override_ledger = Map.get(args, :override_ledger)

    nightly_accrual(
      user,
      Map.get(args, :employment),
      accrual_policy,
      event.date,
      override_ledger
    )
  end

  defp process_event(
         _event = %{amount: amount, date: date, event_type: :taken},
         args = %{
           accrual_policy: accrual_policy,
           user: user
         }
       ) do
    # event |> IO.inspect(label: "processing taken event")
    override_ledger = Map.get(args, :override_ledger)

    taken(
      %{amount: amount, notes: nil, employment: Map.get(args, :employment)},
      user,
      accrual_policy,
      date,
      override_ledger
    )
  end

  defp process_event(
         _event = %{amount: amount, date: date, event_type: :manual},
         args = %{
           accrual_policy: accrual_policy,
           user: user
         }
       ) do
    # event |> IO.inspect(label: "processing manual event")
    override_ledger = Map.get(args, :override_ledger)

    manual_adjustment(%{amount: amount, notes: nil}, user, accrual_policy, date, override_ledger)
  end

  defp process_event(
         _event = %{
           regular_amount: regular_transaction,
           carryover_amount: carryover_transaction,
           date: date,
           event_type: :withdrawn
         },
         args = %{
           accrual_policy: accrual_policy,
           user: user
         }
       ) do
    # event |> IO.inspect(label: "processing withdrawn event")
    override_ledger = Map.get(args, :override_ledger)

    withdrawn(
      regular_transaction,
      carryover_transaction,
      nil,
      user,
      accrual_policy,
      date,
      override_ledger
    )
  end

  defp get_carryover_limit_type(nil) do
    nil
  end

  defp get_carryover_limit_type(carryover_limit) do
    String.downcase(carryover_limit)
  end

  defp pega_client, do: Application.get_env(:velocity, :pega_client, Velocity.Clients.PegaBasic)
end
