defmodule Velocity.Contexts.PersonsTest do
  use Velocity.DataCase

  alias Velocity.Contexts.Persons

  describe "persons" do
    alias Velocity.Schema.Person

    @valid_attrs %{
      email_address: "some email_address",
      first_name: "some first_name",
      full_name: "some full_name",
      last_name: "some last_name",
      phone: "some phone"
    }
    @update_attrs %{
      email_address: "some updated email_address",
      first_name: "some updated first_name",
      full_name: "some updated full_name",
      last_name: "some updated last_name",
      phone: "some updated phone"
    }
    @invalid_attrs %{
      email_address: nil,
      first_name: nil,
      full_name: nil,
      last_name: nil,
      phone: nil
    }

    def person_fixture(attrs \\ %{}) do
      {:ok, person} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Persons.create_person()

      person
    end

    test "list_persons/0 returns all persons" do
      person = person_fixture()
      assert Persons.list_persons() == [person]
    end

    test "get_person!/1 returns the person with given id" do
      person = person_fixture()
      assert Persons.get_person!(person.id) == person
    end

    test "create_person/1 with valid data creates a person" do
      assert {:ok, %Person{} = person} = Persons.create_person(@valid_attrs)
      assert person.email_address == "some email_address"
      assert person.first_name == "some first_name"
      assert person.full_name == "some full_name"
      assert person.last_name == "some last_name"
      assert person.phone == "some phone"
    end

    test "create_person/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Persons.create_person(@invalid_attrs)
    end

    test "update_person/2 with valid data updates the person" do
      person = person_fixture()
      assert {:ok, %Person{} = person} = Persons.update_person(person.id, @update_attrs)
      assert person.email_address == "some updated email_address"
      assert person.first_name == "some updated first_name"
      assert person.full_name == "some updated full_name"
      assert person.last_name == "some updated last_name"
      assert person.phone == "some updated phone"
    end

    test "update_person/2 with invalid data returns error changeset" do
      person = person_fixture()
      assert {:error, %Ecto.Changeset{}} = Persons.update_person(person.id, @invalid_attrs)
      assert person == Persons.get_person!(person.id)
    end

    test "delete_person/1 deletes the person" do
      person = person_fixture()
      assert {:ok, %Person{}} = Persons.delete_person(person.id)
      assert_raise Ecto.NoResultsError, fn -> Persons.get_person!(person.id) end
    end

    test "change_person/1 returns a person changeset" do
      person = person_fixture()
      assert %Ecto.Changeset{} = Persons.change_person(person)
    end
  end
end
