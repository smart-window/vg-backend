defmodule Velocity.Contexts.PartnerManagersTest do
  use Velocity.DataCase

  alias Velocity.Contexts.PartnerManagers
  alias Velocity.Contexts.Partners
  alias Velocity.Contexts.Users

  describe "partner_managers" do
    alias Velocity.Schema.PartnerManager

    @partner_attrs %{
      name: "some partner"
    }
    @user_attrs %{
      email: "test@fubar.com",
      okta_user_uid: "abcdefh"
    }

    def partner_fixture(attrs \\ %{}) do
      {:ok, partner} =
        attrs
        |> Enum.into(@partner_attrs)
        |> Partners.create()

      partner
    end

    def user_fixture(attrs \\ %{country_specific_fields: %{}, settings: %{"language" => "en"}}) do
      {:ok, user} =
        attrs
        |> Enum.into(@user_attrs)
        |> Users.create()

      user
    end

    @update_attrs %{job_title: "some updated job_title"}
    @invalid_attrs %{job_title: nil}

    def partner_manager_fixture(attrs \\ %{}) do
      partner = partner_fixture()
      user = user_fixture()

      {:ok, partner_manager} =
        attrs
        |> Enum.into(%{
          job_title: "a job title",
          partner_id: partner.id,
          user_id: user.id,
          partner: partner,
          user: user
        })
        |> PartnerManagers.create_partner_manager()

      partner_manager
    end

    test "list_partner_managers/0 returns all partner_managers" do
      partner_manager = partner_manager_fixture()
      assert PartnerManagers.list_partner_managers() == [partner_manager]
    end

    test "get_partner_manager!/1 returns the partner_manager with given id" do
      partner_manager = partner_manager_fixture()
      assert PartnerManagers.get_partner_manager!(partner_manager.id) == partner_manager
    end

    test "create_partner_manager/1 with valid data creates a partner_manager" do
      partner = partner_fixture()
      user = user_fixture()

      assert {:ok, %PartnerManager{} = partner_manager} =
               PartnerManagers.create_partner_manager(%{
                 job_title: "some job_title",
                 partner: partner,
                 user: user,
                 partner_id: partner.id,
                 user_id: user.id
               })

      assert partner_manager.job_title == "some job_title"
    end

    test "create_partner_manager/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               PartnerManagers.create_partner_manager(%{
                 partner: partner_fixture(),
                 user: user_fixture()
               })
    end

    test "update_partner_manager/2 with valid data updates the partner_manager" do
      partner_manager = partner_manager_fixture()

      assert {:ok, %PartnerManager{} = partner_manager} =
               PartnerManagers.update_partner_manager(partner_manager.id, @update_attrs)

      assert partner_manager.job_title == "some updated job_title"
    end

    test "update_partner_manager/2 with invalid data returns error changeset" do
      partner_manager = partner_manager_fixture()

      assert {:error, %Ecto.Changeset{}} =
               PartnerManagers.update_partner_manager(partner_manager.id, @invalid_attrs)

      assert partner_manager == PartnerManagers.get_partner_manager!(partner_manager.id)
    end

    test "delete_partner_manager/1 deletes the partner_manager" do
      partner_manager = partner_manager_fixture()
      assert {:ok, %PartnerManager{}} = PartnerManagers.delete_partner_manager(partner_manager.id)

      assert_raise Ecto.NoResultsError, fn ->
        PartnerManagers.get_partner_manager!(partner_manager.id)
      end
    end
  end
end
