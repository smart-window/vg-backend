defmodule Velocity.Schema.FormFormField do
  @moduledoc """
    Schema for form_form_fields.
    Represents an association table between form_fields and forms for
    fields that may differ per-country or per-form.
    Supports overriding most columns in form_fields for the given country/form.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Country
  alias Velocity.Schema.Form
  alias Velocity.Schema.FormField

  schema "form_form_fields" do
    belongs_to :country, Country
    belongs_to :form, Form
    belongs_to :form_field, FormField

    field :type_override, FormFieldTypeEnum
    field :optional_override, :boolean
    field :source_table_override, :string
    field :source_table_field_override, :string
    field :config_override, :map

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :type_override,
      :optional_override,
      :source_table_override,
      :source_table_field_override,
      :config_override,
      :form_id,
      :form_field_id,
      :country_id
    ])
    |> validate_required([:form_id, :form_field_id])
  end
end
