defmodule Velocity.Schema.EmailTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.HTMLSection

  schema "email_templates" do
    field :name, :string
    field :subject, :string
    field :from_role, :string
    field :to_role, :string
    has_many :html_sections, HTMLSection

    timestamps()
  end

  @doc false
  def changeset(email_template, attrs) do
    email_template
    |> cast(attrs, [:name, :subject, :from_role, :to_role])
    |> validate_required([:name])
  end
end
