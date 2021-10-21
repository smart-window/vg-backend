defmodule Velocity.Contexts.Pto.Levels do
  @moduledoc false

  alias Velocity.Repo
  alias Velocity.Schema.Pto.AccrualPolicy
  alias Velocity.Schema.Pto.Level
  alias Velocity.Utils.Dates, as: Utils

  def delete(pega_level_id) do
    level = get_by(pega_level_id: pega_level_id)

    Repo.delete(level)
  end

  def get_by(keyword) do
    Repo.get_by(Level, keyword)
  end

  def determine_level(
        start_date,
        accrual_policy,
        event_date \\ DateTime.utc_now()
      )

  def determine_level(
        start_date,
        %AccrualPolicy{levels: levels},
        event_date
      )
      when is_list(levels) and levels != [] do
    sorted_levels = sort_levels_with_effective_date(start_date, levels)
    find_level(sorted_levels, event_date)
  end

  def determine_level(
        start_date,
        accrual_policy = %AccrualPolicy{},
        event_date
      ) do
    with_levels = Repo.preload(accrual_policy, :levels)

    if with_levels.levels != [] do
      determine_level(start_date, with_levels, event_date)
    else
      nil
    end
  end

  def sort_levels_with_effective_date(start_date, levels) do
    Enum.map(levels, fn level ->
      with_effective_date(start_date, level)
    end)
    # asc
    |> Enum.sort(&(Date.compare(&1.effective_date, &2.effective_date) == :lt))
  end

  def with_effective_date(start_date, level) do
    effective_date = effective_date(level, start_date)
    Map.put(level, :effective_date, effective_date)
  end

  def effective_date(
        %{start_date_interval_unit: unit, start_date_interval: interval},
        hire_date = %Date{}
      ) do
    Timex.shift(hire_date, Keyword.new([{String.to_atom(String.downcase(unit)), interval}]))
  end

  def effective_date(
        level,
        hire_date
      ) do
    date = Utils.parse_pega_date!(hire_date)

    effective_date(level, date)
  end

  def find_level(sorted_levels, event_date) do
    [level_to_check | rest] = sorted_levels
    next_level = List.first(rest)

    if next_level do
      case(
        Timex.between?(event_date, level_to_check.effective_date, next_level.effective_date,
          inclusive: :start
        )
      ) do
        true ->
          level_to_check

        false ->
          find_level(rest, event_date)
      end
    else
      level_to_check
    end
  end

  def get_level!(id) do
    Repo.get!(Level, id)
  end

  def create_level(params) do
    Level.build(params)
    |> Repo.insert()
  end

  def update_level(id, params) do
    Repo.get!(Level, id)
    |> Level.changeset(params)
    |> Repo.update()
  end

  def delete_level(id) do
    Repo.get!(Level, id)
    |> Repo.delete()
  end
end
