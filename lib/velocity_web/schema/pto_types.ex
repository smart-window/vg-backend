defmodule VelocityWeb.Schema.PtoTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo
  alias Velocity.Schema.Pto.PtoRequestDay

  import Ecto.Query

  @request_day_slot_days %{
    :all_day => 1,
    :half_day => 0.5,
    :morning => 0.5,
    :afternoon => 0.5
  }

  @desc "pto ledger"
  object :pto_ledger do
    field :id, :id
    field :event_date, :date
    field :event_type, :string
    field :regular_balance, :float
    field :regular_transaction, :float
    field :carryover_balance, :float
    field :carryover_transaction, :float
    field :user_id, :integer
    field :accrual_policy_id, :integer
  end

  object :accrual_policy do
    field :id, :id
    field :pega_policy_id, :string
    field :label, :string
    field :first_accrual_policy, :string
    field :carryover_day, :string
    field :levels, list_of(:level)

    field(:pto_type, :pto_type) do
      resolve(fn type, _args, _info ->
        pto_type = Ecto.assoc(type, :pto_type) |> Repo.one()
        {:ok, pto_type}
      end)
    end
  end

  @desc "accrual policy report item"
  object :accrual_policy_report_item do
    field :id, :id
    field :name, :string
    field :time_off_type, :string
    field :accrual_max, :float
    field :rollover_max, :float
    field :rollover_date, :string
    field :num_levels, :integer
  end

  @desc "accrual policies report"
  object :accrual_policies_report do
    field :row_count, :integer
    field :accrual_policy_report_items, list_of(:accrual_policy_report_item)
  end

  object :level do
    field :id, :id
    field :start_date_interval, :integer
    field :start_date_interval_unit, :string
    field :pega_level_id, :string
    field :accrual_amount, :float
    field :accrual_period, :string
    field :accrual_frequency, :float
    field :max_days, :float
    field :carryover_limit, :float
    field :carryover_limit_type, :string
    field :accrual_calculation_month_day, :string
    field :accrual_calculation_week_day, :integer
    field :accrual_calculation_year_month, :string
    field :accrual_calculation_year_day, :integer
    field :accrual_policy_id, :id
  end

  object :pto_type do
    field :id, :id
    field :name, :string
  end

  object :pto_request do
    field :id, :id
    field :employment_id, :id
    field :decided_by_user_id, :id
    field :request_comment, :string
    field :decision, :string
    field :decision_comment, :string

    field(:pto_type, :pto_type) do
      resolve(fn pto_request, _args, _info ->
        # In the future, we might need to support multiple types across one pto request
        first_pto_day_type =
          Repo.one(
            from prd in PtoRequestDay,
              join: pt in assoc(prd, :pto_type),
              join: pr in assoc(prd, :pto_request),
              where: pr.id == ^pto_request.id,
              select: pt,
              order_by: [asc: prd.day],
              limit: 1
          )

        {:ok, first_pto_day_type}
      end)
    end

    field(:employment, :employment) do
      resolve(fn pto_request, _args, _info ->
        employment = Ecto.assoc(pto_request, :employment) |> Repo.one()
        {:ok, employment}
      end)
    end

    field(:decided_by_user, :user) do
      resolve(fn pto_request, _args, _info ->
        decided_by_user = Ecto.assoc(pto_request, :decided_by_user) |> Repo.one()
        {:ok, decided_by_user}
      end)
    end

    field(:start_date, :date) do
      resolve(fn pto_request, _args, _info ->
        first_request_day =
          Repo.one(
            from r in PtoRequestDay,
              where: r.pto_request_id == ^pto_request.id,
              order_by: [asc: r.day],
              limit: 1
          )

        {:ok, first_request_day.day}
      end)
    end

    field(:end_date, :date) do
      resolve(fn pto_request, _args, _info ->
        last_request_day =
          Repo.one(
            from r in PtoRequestDay,
              where: r.pto_request_id == ^pto_request.id,
              order_by: [desc: r.day],
              limit: 1
          )

        {:ok, last_request_day.day}
      end)
    end

    field(:total_days, :float) do
      resolve(fn pto_request, _args, _info ->
        all_request_days =
          Repo.all(
            from r in PtoRequestDay,
              where: r.pto_request_id == ^pto_request.id
          )

        total_days =
          Enum.reduce(all_request_days, 0.0, fn day, acc ->
            day_for_slot = Map.get(@request_day_slot_days, day.slot)
            acc + day_for_slot
          end)

        {:ok, total_days}
      end)
    end
  end

  object :pto_request_day do
    field :id, :id
    field :pto_request_id, :id
    field :accrual_policy_id, :id
    field :level_id, :id
    field :pto_type_id, :id
    field :day, :date
    field :slot, :string
    field :start_time, :time
    field :end_time, :time

    field(:pto_request, :pto_request) do
      resolve(fn pto_request, _args, _info ->
        pto_request = Ecto.assoc(pto_request, :pto_request) |> Repo.one()
        {:ok, pto_request}
      end)
    end

    field(:accrual_policy, :accrual_policy) do
      resolve(fn accrual_policy, _args, _info ->
        accrual_policy = Ecto.assoc(accrual_policy, :accrual_policy) |> Repo.one()
        {:ok, accrual_policy}
      end)
    end

    field(:level, :level) do
      resolve(fn level, _args, _info ->
        level = Ecto.assoc(level, :level) |> Repo.one()
        {:ok, level}
      end)
    end

    field(:pto_type, :pto_type) do
      resolve(fn pto_type, _args, _info ->
        pto_type = Ecto.assoc(pto_type, :pto_type) |> Repo.one()
        {:ok, pto_type}
      end)
    end
  end

  object :user_policy do
    field :id, :id
    field :accrual_policy, :accrual_policy
    field :user, :user
    field :end_date, :date
  end

  input_object :input_pto_request_day do
    field :day, :date
    field :slot, :string
  end

  input_object :input_pto_accrual_policy do
    field :carryover_day, :string
    field :label, :string
    field :first_accrual_policy, :string
    field :pega_policy_id, :id
    field :levels, list_of(:input_level)
  end

  input_object :input_level do
    field :pega_level_id, :id
    field :accrual_amount, :float
    field :start_date_interval_unit, :string
    field :start_date_interval, :integer
    field :accrual_calculation_month_day, :string
    field :accrual_calculation_week_day, :integer
    field :accrual_calculation_year_day, :integer
    field :accrual_calculation_year_month, :string
    field :carryover_limit, :integer
    field :carryover_limit_type, :string
    field :max_days, :integer
    field :accrual_period, :string
    field :accrual_frequency, :integer
  end

  input_object :input_taken_event do
    field :id, :id
    field :amount, :float
    field :date, :date
  end

  input_object :input_manual_adjustment_event do
    field :amount, :float
    field :date, :date
  end

  input_object :input_withdrawn_event do
    field :regular_amount, :float
    field :carryover_amount, :float
    field :date, :date
  end
end
