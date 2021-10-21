defmodule Velocity.Contexts.Persons do
  @moduledoc """
  The Contexts.Persons context.
  """

  import Ecto.Query, warn: false
  alias Velocity.Repo

  alias Velocity.Schema.Person

  @doc """
  Returns the list of persons.

  ## Examples

      iex> list_persons()
      [%Person{}, ...]

  """
  def list_persons do
    Repo.all(Person)
  end

  @doc """
  Gets a single person.

  Raises if the Person does not exist.

  ## Examples

      iex> get_person!(123)
      %Person{}

  """
  def get_person!(id), do: Repo.get!(Person, id)

  @doc """
  Creates a person.

  ## Examples

      iex> create_person(%{field: value})
      {:ok, %Person{}}

      iex> create_person(%{field: bad_value})
      {:error, ...}

  """
  def create_person(attrs \\ %{}) do
    %Person{}
    |> Person.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a person.

  ## Examples

      iex> update_person(id, %{field: new_value})
      {:ok, %Person{}}

      iex> update_person(id, %{field: bad_value})
      {:error, ...}

  """
  def update_person(id, attrs) do
    Repo.get!(Person, id)
    |> Person.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Person.

  ## Examples

      iex> delete_person(person)
      {:ok, %Person{}}

      iex> delete_person(person)
      {:error, ...}

  """
  def delete_person(id) do
    %Person{id: id}
    |> Repo.delete()
  end

  @doc """
  Returns a data structure for tracking person changes.

  ## Examples

      iex> change_person(person)
      %Todo{...}

  """
  def change_person(person = %Person{}, attrs \\ %{}) do
    Person.changeset(person, attrs)
  end
end
