defmodule Velocity.Contexts.Pto.LedgersTest do
  use Velocity.DataCase, async: true

  alias Velocity.Contexts.Pto.Ledgers
  alias Velocity.Schema.Pto.Ledger

  import Ecto.Query

  describe "Ledgers.last_ledger_entry/3" do
    test "it returns the last entry for a user / policy" do
      user = Factory.insert(:user)
      accrual_policy = Factory.insert(:accrual_policy)

      ledger =
        Factory.insert(:ledger, %{
          user: user,
          accrual_policy: accrual_policy
        })

      last_ledger = Ledgers.last_ledger_entry(user, accrual_policy)
      assert last_ledger.id == ledger.id
    end
  end

  describe "Ledgers.delete_ledgers/2" do
    test "it removes ledger entries" do
      user = Factory.insert(:user)
      accrual_policy = Factory.insert(:accrual_policy)

      [first | _rest] =
        Factory.insert_list(10, :ledger, %{user: user, accrual_policy: accrual_policy})

      Ledgers.delete_ledgers(first.user_id, first.accrual_policy_id)

      assert Repo.aggregate(from(l in Ledger, where: l.deleted == false), :count) == 0
    end
  end
end
