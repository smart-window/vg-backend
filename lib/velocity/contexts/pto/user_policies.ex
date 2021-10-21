defmodule Velocity.Contexts.Pto.UserPolicies do
  @moduledoc "context for user policies"

  require Logger

  alias Ecto.Multi
  alias Velocity.Contexts.Employments
  alias Velocity.Contexts.Pto.Levels
  alias Velocity.Repo
  alias Velocity.Schema.Pto.AccrualPolicy
  alias Velocity.Schema.Pto.Ledger
  alias Velocity.Schema.Pto.UserPolicy
  alias Velocity.Schema.User
  alias Velocity.Utils.Dates, as: Utils

  import Ecto.Query

  @spec assign_user_policy(%User{id: integer()}, %AccrualPolicy{}, any()) ::
          {:ok, map()} | {:error, any()}
  def assign_user_policy(
        user,
        start_date,
        accrual_policy,
        event_date \\ Date.utc_today()
      ) do
    case get_by(user_id: user.id, accrual_policy_id: accrual_policy.id) do
      nil ->
        user_policy_changeset =
          UserPolicy.changeset(%UserPolicy{}, %{user: user, accrual_policy: accrual_policy})

        level = Levels.determine_level(start_date, accrual_policy, event_date)
        employment = Employments.get_for_user(user.id)

        ledger_changeset =
          Ledger.build(%{
            event_date: event_date,
            event_type: "policy_assignment",
            regular_balance: 0,
            regular_transaction: 0,
            carryover_balance: 0,
            carryover_transaction: 0,
            accrual_policy: accrual_policy,
            employment: employment,
            user: user,
            level: level
          })

        add_policy_and_initial_assignment =
          Multi.new()
          |> Multi.insert(:user_policy, user_policy_changeset,
            on_conflict: [set: [updated_at: DateTime.utc_now()]],
            conflict_target: [:user_id, :accrual_policy_id],
            returning: true
          )
          |> Multi.insert(:ledger, ledger_changeset)

        Repo.transaction(add_policy_and_initial_assignment)

      user_policy = %UserPolicy{} ->
        {:ok, user_policy}
    end
  end

  def assign_user_policies(user, start_date, pega_policy_ids, event_date \\ Date.utc_today()) do
    user
    |> User.changeset(%{start_date: Utils.parse_pega_date!(start_date)})
    |> Repo.update!()

    multi =
      Enum.reduce(pega_policy_ids, Multi.new(), fn pega_policy_id, acc ->
        # credo:disable-for-lines:5 Credo.Check.Refactor.Nesting
        Multi.run(acc, pega_policy_id, fn repo, _ ->
          case repo.get_by(AccrualPolicy, pega_policy_id: pega_policy_id) do
            nil -> {:error, "policy not found with pega_policy_id: #{pega_policy_id}"}
            accrual_policy -> {:ok, accrual_policy}
          end
        end)
        |> Multi.update_all(
          "delete_ledgers-" <> pega_policy_id,
          fn %{
               ^pega_policy_id => accrual_policy
             } ->
            from(l in Ledger,
              where: l.user_id == ^user.id and l.accrual_policy_id == ^accrual_policy.id,
              update: [set: [deleted: true]]
            )
          end,
          []
        )
        |> Multi.insert(
          "assign_policy-" <> pega_policy_id,
          fn %{
               ^pega_policy_id => accrual_policy
             } ->
            UserPolicy.build(%{user: user, accrual_policy: accrual_policy})
          end,
          on_conflict: [set: [updated_at: DateTime.utc_now()]],
          conflict_target: [:user_id, :accrual_policy_id],
          returning: true
        )
        |> Multi.insert("policy_assignment-" <> pega_policy_id, fn %{
                                                                     ^pega_policy_id =>
                                                                       accrual_policy
                                                                   } ->
          level = Levels.determine_level(start_date, accrual_policy, event_date)
          employment = Employments.get_for_user(user.id)

          Ledger.build(%{
            event_date: event_date,
            event_type: "policy_assignment",
            regular_balance: 0,
            regular_transaction: 0,
            carryover_balance: 0,
            carryover_transaction: 0,
            accrual_policy: accrual_policy,
            employment: employment,
            user: user,
            level: level
          })
        end)
      end)

    Repo.transaction(multi)
  end

  @spec remove_user_policies(%User{id: integer()}, list(%AccrualPolicy{})) ::
          {:ok, map()} | {:error, any()}
  def remove_user_policies(user, accrual_policies) do
    accrual_policy_ids = Enum.map(accrual_policies, & &1.id)

    delete_user_policies_query =
      from(up in UserPolicy,
        where: up.accrual_policy_id in ^accrual_policy_ids and up.user_id == ^user.id
      )

    remove_user_policies =
      Multi.new()
      |> Multi.delete_all(:user_polices, delete_user_policies_query)
      |> Multi.update_all(
        :update_all,
        fn _ ->
          from(l in Ledger,
            where: l.user_id == ^user.id and l.accrual_policy_id in ^accrual_policy_ids,
            update: [set: [deleted: true]]
          )
        end,
        []
      )

    Repo.transaction(remove_user_policies)
  end

  def get_by(keyword) do
    Repo.get_by(UserPolicy, keyword)
  end

  def for_user(user_id) do
    query = from(u in UserPolicy, where: u.user_id == ^user_id)

    query
    |> Repo.all()
    |> Repo.preload([:user, :accrual_policy])
  end

  def get_user_policy!(accrual_policy_id, user_id) do
    Repo.get_by!(UserPolicy, accrual_policy_id: accrual_policy_id, user_id: user_id)
    |> Repo.preload([:user, :accrual_policy])
  end

  def deactivate_user_policy(accrual_policy_id, user_id, end_date) do
    user_policy =
      Repo.get_by!(UserPolicy, accrual_policy_id: accrual_policy_id, user_id: user_id)
      |> Repo.preload([:user, :accrual_policy])

    user_policy
    |> UserPolicy.changeset(%{
      end_date: end_date,
      accrual_policy: user_policy.accrual_policy,
      user: user_policy.user
    })
    |> Repo.update()
  end
end
