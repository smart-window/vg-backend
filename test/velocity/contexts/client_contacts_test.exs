defmodule Velocity.Contexts.ClientContactsTest do
  use Velocity.DataCase

  alias Velocity.Contexts.ClientContacts

  describe "client_contacts" do
    alias Velocity.Schema.ClientContact

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

    def client_fixture(attrs \\ %{}) do
      Factory.insert(:client, attrs)
    end

    def client_contact_fixture(attrs \\ %{}) do
      client = client_fixture()

      {:ok, client_contact} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Enum.into(%{client: client})
        |> ClientContacts.create_client_contact()

      client_contact
    end

    test "list_client_contacts/0 returns all client_contacts" do
      client_contact = client_contact_fixture()
      assert ClientContacts.list_client_contacts() == [client_contact]
    end

    test "get_client_contact!/1 returns the client_contact with given id" do
      client_contact = client_contact_fixture()
      assert ClientContacts.get_client_contact!(client_contact.id) == client_contact
    end

    test "create_client_contact/1 with valid data creates a client_contact for a user" do
      client = client_fixture()
      user = user_fixture()

      assert {:ok, %ClientContact{} = client_contact} =
               ClientContacts.create_client_contact(
                 Map.merge(@valid_attrs, %{client: client, user: user})
               )

      assert client_contact.is_primary == true
      assert client_contact.user_id == user.id
    end

    test "create_client_contact/1 with valid data creates a client_contact for a person" do
      client = client_fixture()
      person = person_fixture()

      assert {:ok, %ClientContact{} = client_contact} =
               ClientContacts.create_client_contact(
                 Map.merge(@valid_attrs, %{client: client, person: person})
               )

      assert client_contact.is_primary == true
      assert client_contact.person_id == person.id
    end

    test "create_client_contact/1 with invalid data returns error changeset" do
      client = client_fixture()

      assert {:error, %Ecto.Changeset{}} =
               ClientContacts.create_client_contact(Map.merge(@invalid_attrs, %{client: client}))
    end

    test "update_client_contact/2 with valid data updates the client_contact" do
      client_contact = client_contact_fixture()

      assert {:ok, %ClientContact{} = client_contact} =
               ClientContacts.update_client_contact(client_contact.id, @update_attrs)

      assert client_contact.is_primary == false
    end

    test "update_client_contact/2 with invalid data returns error changeset" do
      client_contact = client_contact_fixture()

      assert {:error, %Ecto.Changeset{}} =
               ClientContacts.update_client_contact(client_contact.id, @invalid_attrs)

      assert client_contact == ClientContacts.get_client_contact!(client_contact.id)
    end

    test "delete_client_contact/1 deletes the client_contact" do
      client_contact = client_contact_fixture()
      assert {:ok, %ClientContact{}} = ClientContacts.delete_client_contact(client_contact.id)

      assert_raise Ecto.NoResultsError, fn ->
        ClientContacts.get_client_contact!(client_contact.id)
      end
    end

    test "change_client_contact/1 returns a client_contact changeset" do
      client_contact = client_contact_fixture()
      assert %Ecto.Changeset{} = ClientContacts.change_client_contact(client_contact)
    end
  end
end
