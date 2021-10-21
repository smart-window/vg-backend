defmodule Velocity.Schema.Form do
  @moduledoc """
    Schema for forms.
    Represents a domain-specific grouping of fields.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.FormFormField
  alias Velocity.Schema.Task

  schema "forms" do
    field :slug, :string
    belongs_to :task, Task

    has_many :form_form_fields, FormFormField
    has_many :form_fields, through: [:form_form_fields, :form_field]

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:slug, :task_id])
    |> validate_required([:slug])
  end
end
