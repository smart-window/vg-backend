defmodule Velocity.Schema.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "persons" do
    field :first_name, :string
    field :last_name, :string
    field :full_name, :string
    field :email_address, :string
    field :phone, :string

    timestamps()
  end

  @doc false
  def changeset(person, attrs) do
    person
    |> cast(attrs, [
      :first_name,
      :last_name,
      :full_name,
      :email_address,
      :phone
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :full_name,
      :email_address
    ])
  end
end
