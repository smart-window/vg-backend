defmodule Velocity.Release do
  @moduledoc false

  alias Velocity.Contexts.Okta
  alias Velocity.Jobs
  alias Velocity.Seeds.DocumentSeeds
  alias Velocity.Seeds.ProcessSeeds

  require Logger

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def pending_migrations? do
    repos()
    |> Enum.any?(fn repo ->
      Ecto.Migrator.migrations(repo)
      |> Enum.any?(fn {status, _version, _migration} -> status == :down end)
    end)
  end

  def sync_okta_users do
    load_app()

    Okta.sync_okta_users()
  end

  def nightly_accrual do
    load_app()

    Jobs.nightly_accrual()
  end

  def print_env_var(varname) do
    Logger.info(Application.get_env(:velocity, String.to_atom(varname)))
  end

  # Velocity.Release.run_function("Velocity.Contexts.TimeTracking", "get_all_time_types", [])
  # Velocity.Release.run_function("Velocity.Contexts.Countries", "get_by", [[id: 1]])
  def run_function(module, function, args) do
    load_app()

    apply(String.to_atom("Elixir.#{module}"), String.to_atom(function), args)
  end

  # bin/velocity,eval,Velocity.Release.seed_processes
  def seed_processes do
    load_app()

    ProcessSeeds.create()
  end

  # bin/velocity,eval,Velocity.Release.seed_documents
  def seed_documents do
    load_app()

    DocumentSeeds.create()
  end

  def seed do
    load_app()

    Code.eval_file("#{:code.priv_dir(:velocity)}/repo/seeds.exs")
  end

  def nightly_accrual(start_and_end_string) do
    load_app()

    start_and_end_strings = String.split(start_and_end_string, "_")
    start_date = NaiveDateTime.from_iso8601!(List.first(start_and_end_strings))
    end_date = NaiveDateTime.from_iso8601!(List.last(start_and_end_strings))

    Jobs.nightly_accrual(start_date: start_date, end_date: end_date)
  end

  def nightly_accrual(start_string, end_string) do
    load_app()

    start_date = NaiveDateTime.from_iso8601!(start_string)
    end_date = NaiveDateTime.from_iso8601!(end_string)

    Jobs.nightly_accrual(start_date: start_date, end_date: end_date)
  end

  def backfill_pto do
    load_app()

    Jobs.backfill_pto()
  end

  def backfill_pto_from(employment_id) do
    load_app()

    Jobs.backfill_pto_from(employment_id)
  end

  def backfill_pto_for(employment_id) do
    load_app()

    Jobs.backfill_pto_for(employment_id)
  end

  def backfill_pto_for_batch(employment_ids) do
    load_app()

    String.split(employment_ids, "_")
    |> Enum.each(fn id ->
      Jobs.backfill_pto_for(String.to_integer(id))
    end)
  end

  defp repos do
    Application.fetch_env!(:velocity, :ecto_repos)
  end

  defp load_app do
    Application.put_env(:velocity, :minimal, true)
    {:ok, _} = Application.ensure_all_started(:velocity)
  end
end
