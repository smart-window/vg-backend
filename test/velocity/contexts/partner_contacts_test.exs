defmodule Velocity.Contexts.PartnerContactsTest do
  use Velocity.DataCase

  alias Velocity.Contexts.PartnerContacts

  describe "partner_contacts" do
    alias Velocity.Schema.PartnerContact

    @valid_attrs %{is_primary: true}
    @update_attrs %{is_primary: false}
    @invalid_attrs %{is_primary: nil}

    def person_fixture(attrs \\ %{}) do
      Factory.insert(
        :person,
        Map.merge(
          %{
            first_name: "John",
            last_name: "Doe",
            full_name: "John Doe",
            email_address: "john.doe@fubar.com"
          },
          attrs
        )
      )
    end

    def user_fixture(attrs \\ %{}) do
      Factory.insert(:user, attrs)
    end

    def partner_fixture(attrs \\ %{}) do
      Factory.insert(:partner, attrs)
    end

    def partner_contact_fixture(attrs \\ %{}) do
      partner = partner_fixture()

      {:ok, partner_contact} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Enum.into(%{partner: partner})
        |> PartnerContacts.create_partner_contact()

      partner_contact
    end

    test "list_partner_contacts/0 returns all partner_contacts" do
      partner_contact = partner_contact_fixture()
      assert PartnerContacts.list_partner_contacts() == [partner_contact]
    end

    test "get_partner_contact!/1 returns the partner_contact with given id" do
      partner_contact = partner_contact_fixture()
      assert PartnerContacts.get_partner_contact!(partner_contact.id) == partner_contact
    end

    test "create_partner_contact/1 with valid data creates a partner_contact for a user" do
      partner = partner_fixture()
      user = user_fixture()

      assert {:ok, %PartnerContact{} = partner_contact} =
               PartnerContacts.create_partner_contact(
                 Map.merge(@valid_attrs, %{partner: partner, user: user})
               )

      assert partner_contact.is_primary == true
      assert partner_contact.user_id == user.id
    end

    test "create_partner_contact/1 with valid data creates a partner_contact for a person" do
      partner = partner_fixture()
      person = person_fixture()

      assert {:ok, %PartnerContact{} = partner_contact} =
               PartnerContacts.create_partner_contact(
                 Map.merge(@valid_attrs, %{partner: partner, person: person})
               )

      assert partner_contact.is_primary == true
      assert partner_contact.person_id == person.id
    end

    test "create_partner_contact/1 with invalid data returns error changeset" do
      partner = partner_fixture()

      assert {:error, %Ecto.Changeset{}} =
               PartnerContacts.create_partner_contact(
                 Map.merge(@invalid_attrs, %{partner: partner})
               )
    end

    test "update_partner_contact/2 with valid data updates the partner_contact" do
      partner_contact = partner_contact_fixture()

      assert {:ok, %PartnerContact{} = partner_contact} =
               PartnerContacts.update_partner_contact(partner_contact.id, @update_attrs)

      assert partner_contact.is_primary == false
    end

    test "update_partner_contact/2 with invalid data returns error changeset" do
      partner_contact = partner_contact_fixture()

      assert {:error, %Ecto.Changeset{}} =
               PartnerContacts.update_partner_contact(partner_contact.id, @invalid_attrs)

      assert partner_contact == PartnerContacts.get_partner_contact!(partner_contact.id)
    end

    test "delete_partner_contact/1 deletes the partner_contact" do
      partner_contact = partner_contact_fixture()
      assert {:ok, %PartnerContact{}} = PartnerContacts.delete_partner_contact(partner_contact.id)

      assert_raise Ecto.NoResultsError, fn ->
        PartnerContacts.get_partner_contact!(partner_contact.id)
      end
    end

    test "change_partner_contact/1 returns a partner_contact changeset" do
      partner_contact = partner_contact_fixture()
      assert %Ecto.Changeset{} = PartnerContacts.change_partner_contact(partner_contact)
    end
  end
end
